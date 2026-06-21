"""Public API of this context.

★ Other contexts ONLY import from this file. Importing any other internal
  module from another context is blocked by the PreToolUse hook.

Example usage from another context::

    from contexts.{this_ctx}.application.api import {ThisCtx}API
    {ThisCtx}API.do_something(SomeCommand(...))

Implementation pattern (uncomment + adapt when filling in):

    from .command import IssueInvoiceCommand
    from .query import GetInvoiceQuery
    from .use_case import IssueInvoice, GetInvoice

    class TemplateAPI:
        @staticmethod
        def issue_invoice(cmd: IssueInvoiceCommand) -> "InvoiceId":
            return IssueInvoice().execute(cmd)

        @staticmethod
        def get_invoice(q: GetInvoiceQuery) -> "InvoiceView":
            return GetInvoice().execute(q)
"""

# Replace this stub with real exports when you copy this template.
__all__: list[str] = []
