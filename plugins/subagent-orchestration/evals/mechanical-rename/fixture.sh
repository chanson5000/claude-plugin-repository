#!/usr/bin/env bash
# Scaffold: small "shop" package where calc_total is used across several files,
# including a string reference resolved with getattr. All tests pass initially.
set -euo pipefail
mkdir -p shop tests

cat > shop/__init__.py <<'EOF'
"""Tiny shop library."""
from shop.pricing import calc_total

__all__ = ["calc_total", "Cart", "Invoice"]

from shop.cart import Cart  # noqa: E402
from shop.invoice import Invoice  # noqa: E402
EOF

cat > shop/pricing.py <<'EOF'
"""Pricing helpers."""

TAX_RATE = 0.10


def calc_total(prices, tax_rate=TAX_RATE):
    """Return the total of `prices` including tax, rounded to cents."""
    subtotal = sum(prices)
    return round(subtotal * (1 + tax_rate), 2)
EOF

cat > shop/cart.py <<'EOF'
"""Shopping cart."""
from shop.pricing import calc_total


class Cart:
    def __init__(self):
        self._items = []

    def add(self, name, price):
        self._items.append((name, price))

    def total(self):
        return calc_total([price for _, price in self._items])
EOF

cat > shop/invoice.py <<'EOF'
"""Invoice rendering."""
import shop.pricing as pricing


class Invoice:
    def __init__(self, customer, prices):
        self.customer = customer
        self.prices = list(prices)

    def render(self):
        total = pricing.calc_total(self.prices)
        return f"Invoice for {self.customer}: {total:.2f}"
EOF

cat > shop/report.py <<'EOF'
"""Order reporting."""
from shop import pricing


def order_totals(orders):
    """Return the total of each order (a list of prices)."""
    return [pricing.calc_total(order) for order in orders]


def grand_total(orders):
    return round(sum(order_totals(orders)), 2)
EOF

cat > shop/hooks.py <<'EOF'
"""Lets configuration pick the pricing function by name."""
from shop import pricing

DEFAULT_TOTAL_FUNCTION = "calc_total"


def resolve_total_function(name=DEFAULT_TOTAL_FUNCTION):
    """Look up a pricing function by its name."""
    return getattr(pricing, name)
EOF

touch tests/__init__.py
cat > tests/test_pricing.py <<'EOF'
import unittest

from shop.pricing import calc_total


class PricingTests(unittest.TestCase):
    def test_total_includes_tax(self):
        self.assertEqual(calc_total([10, 20]), 33.0)

    def test_custom_tax_rate(self):
        self.assertEqual(calc_total([100], tax_rate=0.2), 120.0)

    def test_empty(self):
        self.assertEqual(calc_total([]), 0)
EOF

cat > tests/test_cart.py <<'EOF'
import unittest

from shop.cart import Cart


class CartTests(unittest.TestCase):
    def test_total(self):
        cart = Cart()
        cart.add("pen", 10)
        cart.add("book", 20)
        self.assertEqual(cart.total(), 33.0)
EOF

cat > tests/test_invoice.py <<'EOF'
import unittest

from shop.invoice import Invoice


class InvoiceTests(unittest.TestCase):
    def test_render(self):
        self.assertEqual(Invoice("Ada", [10, 20]).render(), "Invoice for Ada: 33.00")
EOF

cat > tests/test_report.py <<'EOF'
import unittest

from shop import report


class ReportTests(unittest.TestCase):
    def test_order_totals(self):
        self.assertEqual(report.order_totals([[10], [20, 20]]), [11.0, 44.0])

    def test_grand_total(self):
        self.assertEqual(report.grand_total([[10], [20, 20]]), 55.0)
EOF

cat > tests/test_hooks.py <<'EOF'
import unittest

from shop import hooks, pricing


class HooksTests(unittest.TestCase):
    def test_default_resolves_to_pricing_function(self):
        func = hooks.resolve_total_function()
        self.assertIs(func, getattr(pricing, hooks.DEFAULT_TOTAL_FUNCTION))
        self.assertEqual(func([10]), 11.0)
EOF
