#!/usr/bin/env bash
# Scaffold: reports package. reports/sales.py renders pages using
# reports/pagination.py, which has an off-by-one (treats 1-indexed pages as 0-indexed).
# tests/test_sales.py has two failing tests; the other tests pass.
set -euo pipefail
mkdir -p reports tests

touch reports/__init__.py tests/__init__.py

cat > reports/pagination.py <<'EOF'
"""Pagination helpers shared by the report modules."""


def page_count(total_items, per_page):
    """Number of pages needed for `total_items` (always at least 1)."""
    if per_page < 1:
        raise ValueError("per_page must be positive")
    return max(1, -(-total_items // per_page))


def paginate(items, page, per_page):
    """Return the slice of `items` shown on `page`.

    Pages are 1-indexed: page 1 is the first page.
    """
    if per_page < 1:
        raise ValueError("per_page must be positive")
    start = page * per_page
    return items[start:start + per_page]
EOF

cat > reports/sales.py <<'EOF'
"""Plain-text sales report."""
from reports.pagination import page_count, paginate

PER_PAGE = 4


def render_page(rows, page, per_page=PER_PAGE):
    """Render one page of (name, amount) rows as text."""
    pages = page_count(len(rows), per_page)
    lines = [f"Sales report - page {page} of {pages}"]
    for name, amount in paginate(rows, page, per_page):
        lines.append(f"{name}: {amount:.2f}")
    return "\n".join(lines)


def total(rows):
    return round(sum(amount for _, amount in rows), 2)
EOF

cat > tests/test_pagination.py <<'EOF'
import unittest

from reports.pagination import page_count


class PageCountTests(unittest.TestCase):
    def test_exact_multiple(self):
        self.assertEqual(page_count(8, 4), 2)

    def test_partial_last_page(self):
        self.assertEqual(page_count(10, 4), 3)

    def test_empty_has_one_page(self):
        self.assertEqual(page_count(0, 4), 1)

    def test_rejects_bad_page_size(self):
        with self.assertRaises(ValueError):
            page_count(5, 0)
EOF

cat > tests/test_sales.py <<'EOF'
import unittest

from reports import sales

ROWS = [(f"Row {i}", float(i)) for i in range(1, 11)]  # Row 1 .. Row 10


class SalesReportTests(unittest.TestCase):
    def test_header_reports_page_and_page_count(self):
        header = sales.render_page(ROWS, 1).splitlines()[0]
        self.assertEqual(header, "Sales report - page 1 of 3")

    def test_first_page_lists_first_rows(self):
        lines = sales.render_page(ROWS, 1).splitlines()[1:]
        self.assertEqual(lines, ["Row 1: 1.00", "Row 2: 2.00", "Row 3: 3.00", "Row 4: 4.00"])

    def test_last_page_lists_remaining_rows(self):
        lines = sales.render_page(ROWS, 3).splitlines()[1:]
        self.assertEqual(lines, ["Row 9: 9.00", "Row 10: 10.00"])

    def test_total(self):
        self.assertEqual(sales.total(ROWS), 55.0)
EOF
