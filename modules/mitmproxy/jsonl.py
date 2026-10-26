"""
Record HTTP flows as JSON lines, one file per labelled recording.

Commands:
  jsonl.start LABEL        record matching flows to <jsonl_dir>/LABEL.jsonl
  jsonl.stop               stop recording
  jsonl.toggle             stop if recording, otherwise prompt for a label
  jsonl.note TEXT          write a marker line into the current recording
  jsonl.export FLOWS PATH  write the given flows, e.g. @marked, to PATH
"""

import json
import logging
import re
from collections.abc import Sequence
from datetime import datetime
from pathlib import Path
from typing import IO, Any, Optional

import mitmproxy.types
from mitmproxy import command, ctx, exceptions, flow, flowfilter, http
from mitmproxy.log import ALERT

SECRET_HEADERS = {
    "authorization",
    "proxy-authorization",
    "cookie",
    "set-cookie",
    "x-csrf-token",
    "x-xsrf-token",
}


class Jsonl:
    def __init__(self) -> None:
        self.file: IO[str] | None = None
        self.path: Path | None = None
        self.filt: flowfilter.TFilter | None = None
        # The same secret always gets the same placeholder, so it can be traced
        # from the response that issued it to the requests that use it.
        self.placeholders: dict[str, str] = {}

    def load(self, loader):
        loader.add_option(
            "jsonl_dir",
            str,
            "~/.mitmproxy/captures",
            "Directory for jsonl recordings and relative export paths.",
        )
        loader.add_option(
            "jsonl_filter",
            Optional[str],
            "!~a",
            "Filter which flows are recorded by jsonl.start.",
        )
        loader.add_option(
            "jsonl_redact",
            bool,
            True,
            "Replace auth and cookie header values with stable placeholders.",
        )

    def configure(self, updated):
        if "jsonl_filter" in updated:
            if ctx.options.jsonl_filter:
                try:
                    self.filt = flowfilter.parse(ctx.options.jsonl_filter)
                except ValueError as e:
                    raise exceptions.OptionsError(str(e)) from e
            else:
                self.filt = None

    def done(self):
        self._close()

    def _resolve(self, path: str) -> Path:
        p = Path(path).expanduser()
        if not p.is_absolute():
            p = Path(ctx.options.jsonl_dir).expanduser() / p
        p.parent.mkdir(parents=True, exist_ok=True)
        return p

    def _close(self) -> None:
        if self.file:
            self.file.close()
            self.file = None
            self.path = None

    @command.command("jsonl.start")
    def start(self, label: str) -> None:
        """Record matching flows to <jsonl_dir>/LABEL.jsonl, appending if it exists."""
        name = re.sub(r"[^\w.-]+", "-", label).strip("-")
        if not name:
            raise exceptions.CommandError("jsonl.start needs a label")
        self._close()
        self.path = self._resolve(f"{name}.jsonl")
        self.file = self.path.open("a", encoding="utf8")
        logging.log(ALERT, f"jsonl: recording to {self.path}")

    @command.command("jsonl.stop")
    def stop(self) -> None:
        """Stop recording."""
        if not self.file:
            logging.log(ALERT, "jsonl: not recording")
            return
        path = self.path
        self._close()
        logging.log(ALERT, f"jsonl: stopped recording to {path}")

    @command.command("jsonl.toggle")
    def toggle(self) -> None:
        """Stop recording, or prompt for a label to start one."""
        if self.file:
            self.stop()
        else:
            ctx.master.commands.call("console.command", "jsonl.start")

    @command.command("jsonl.note")
    def note(self, *text: str) -> None:
        """Write a marker line into the current recording."""
        if not self.file:
            raise exceptions.CommandError("jsonl: not recording")
        self._write(self.file, {"note": " ".join(text), "ts": _now()})

    @command.command("jsonl.export")
    def export(self, flows: Sequence[flow.Flow], path: mitmproxy.types.Path) -> None:
        """Write HTTP flows to PATH (relative to jsonl_dir), overwriting it."""
        p = self._resolve(path)
        n = 0
        with p.open("w", encoding="utf8") as f:
            for fl in flows:
                if isinstance(fl, http.HTTPFlow):
                    self._write(f, self._record(fl))
                    n += 1
        logging.log(ALERT, f"jsonl: exported {n} flows to {p}")

    def response(self, f: http.HTTPFlow) -> None:
        if self.file and (self.filt is None or self.filt(f)):
            self._write(self.file, self._record(f))

    def error(self, f: http.HTTPFlow) -> None:
        self.response(f)

    def _write(self, file: IO[str], obj: dict) -> None:
        file.write(json.dumps(obj, ensure_ascii=False) + "\n")
        file.flush()

    def _record(self, f: http.HTTPFlow) -> dict:
        req = f.request
        rec: dict[str, Any] = {
            "ts": datetime.fromtimestamp(req.timestamp_start).isoformat(
                timespec="milliseconds"
            ),
            "method": req.method,
            "url": req.pretty_url,
            "status": f.response.status_code if f.response else None,
            "request": {
                "headers": self._headers(req.headers),
                "query": _multi(req.query.items(multi=True)) if req.query else None,
                "body": _body(req),
            },
        }
        if f.response:
            rec["response"] = {
                "headers": self._headers(f.response.headers),
                "body": _body(f.response),
            }
        if f.error:
            rec["error"] = f.error.msg
        if f.comment:
            rec["comment"] = f.comment
        return rec

    def _headers(self, headers) -> dict:
        return _multi(
            (k.lower(), self._redact_header(k.lower(), v))
            for k, v in headers.items(multi=True)
        )

    def _redact_header(self, name: str, value: str) -> str:
        if not ctx.options.jsonl_redact or name not in SECRET_HEADERS:
            return value
        # Keep cookie names, cookie attributes and the auth scheme visible;
        # they matter for working out how the API authenticates.
        if name == "cookie":
            return "; ".join(
                self._redact_pair(c) for c in value.split(";") if c.strip()
            )
        if name == "set-cookie":
            first, sep, attrs = value.partition(";")
            return self._redact_pair(first) + sep + attrs
        scheme, sep, cred = value.partition(" ")
        if sep and scheme.isalpha():
            return f"{scheme} {self._redact(cred)}"
        return self._redact(value)

    def _redact_pair(self, pair: str) -> str:
        k, sep, v = pair.strip().partition("=")
        return f"{k}={self._redact(v)}" if sep else self._redact(k)

    def _redact(self, value: str) -> str:
        if value not in self.placeholders:
            self.placeholders[value] = f"<secret-{len(self.placeholders) + 1}>"
        return self.placeholders[value]


def _now() -> str:
    return datetime.now().isoformat(timespec="milliseconds")


def _multi(pairs) -> dict:
    """Collect pairs into a dict, turning repeated keys into lists."""
    d: dict[str, Any] = {}
    for k, v in pairs:
        if k not in d:
            d[k] = v
        elif isinstance(d[k], list):
            d[k].append(v)
        else:
            d[k] = [d[k], v]
    return d


def _body(msg: http.Message) -> Any:
    content = msg.get_content(strict=False)
    if not content:
        return None
    ctype = msg.headers.get("content-type", "")
    if "json" in ctype:
        try:
            return json.loads(content)
        except ValueError:
            pass
    if "form-urlencoded" in ctype and isinstance(msg, http.Request):
        return _multi(msg.urlencoded_form.items(multi=True))
    text = msg.get_text(strict=False)
    if text is not None and _is_text(ctype, text):
        return text
    return {"binary": len(content), "content-type": ctype}


def _is_text(ctype: str, text: str) -> bool:
    if ctype.startswith("text/") or any(
        t in ctype for t in ("json", "xml", "javascript", "graphql")
    ):
        return True
    return "\x00" not in text


addons = [Jsonl()]
