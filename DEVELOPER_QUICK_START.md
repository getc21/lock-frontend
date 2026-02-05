# Quick Reference Guide - Quotations & Cash Register Features

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                      UI Pages (5)                        │
│   Quotations | Detail | Create | CashRegister | Movements│
└────────────────────┬────────────────────────────────────┘
                     │ Consumer Widget + ref.watch()
┌────────────────────▼────────────────────────────────────┐
│            State Notifiers (5 providers)                 │
│  QuotationList | Detail | Form | CashRegister | Movements│
└────────────────────┬────────────────────────────────────┘
                     │ Manage state & business logic
┌────────────────────▼────────────────────────────────────┐
│               API Services (2 providers)                 │
│          QuotationApi | CashRegisterApi                  │
└────────────────────┬────────────────────────────────────┘
                     │ HTTP requests
┌────────────────────▼────────────────────────────────────┐
│                 Backend API Server                       │
│         REST endpoints for quotations & cash             │
└─────────────────────────────────────────────────────────┘
```

## Common Tasks & Code Examples

### 1. Access Quotation List

```dart
// In a ConsumerWidget
final state = ref.watch(quotationListProvider(storeId));

// Load quotations
await ref.read(quotationListProvider(storeId).notifier).loadQuotations();

// Filter by status
await ref.read(quotationListProvider(storeId).notifier).setStatusFilter('pending');

// Filter by date range
await ref.read(quotationListProvider(storeId).notifier).setDateRange(start, end);
```

### 2. Create New Quotation

```dart
final formState = ref.watch(quotationFormProvider(storeId));
final notifier = ref.read(quotationFormProvider(storeId).notifier);

// Add item
notifier.addItem(QuotationItem(
  productId: '1',
  productName: 'Product Name',
  quantity: 1,
  price: 100.0,
));

// Set discount
notifier.setDiscountAmount(10.0);

// Submit
final result = await notifier.submitQuotation(
  customerId: 'cust123',
  customerName: 'Customer Name',
);
```

### 3. View Quotation Details

```dart
final detailState = ref.watch(quotationDetailProvider(quotationId));

// Refresh
await ref.read(quotationDetailProvider(quotationId).notifier).refreshQuotation();

// Convert to order
await ref.read(quotationDetailProvider(quotationId).notifier).convertToOrder();
```

### 4. Cash Register Operations

```dart
final cashState = ref.watch(cashRegisterProvider(storeId));

// Open cash register
await ref.read(cashRegisterProvider(storeId).notifier).openCash(500.0);

// Add movement
await ref.read(cashRegisterProvider(storeId).notifier).addMovement(
  type: 'entrada',
  amount: 100.0,
  description: 'Deposit from owner',
);

// Close cash register
await ref.read(cashRegisterProvider(storeId).notifier).closeCash(650.0);
```

### 5. View Cash Movements

```dart
final movementsState = ref.watch(cashMovementsProvider(cashRegisterId));

// Load movements for date range
await ref.read(cashMovementsProvider(cashRegisterId).notifier).loadMovements(
  startDate: DateTime.now(),
  endDate: DateTime.now(),
);

// Filter by type
ref.read(cashMovementsProvider(cashRegisterId).notifier).setTypeFilter('venta_qr');

// Get summary
final summary = ref.read(cashMovementsProvider(cashRegisterId).notifier).getSummary();
```

## Navigation Patterns

### Navigate to Pages

```dart
// List pages
context.go('/quotations');
context.go('/cash-register');
context.go('/cash-movements');

// Detail/Create pages
context.go('/quotations/${quotationId}');
context.go('/quotations/create');
```

## File Locations Quick Reference

| Feature | File Location |
|---------|--------------|
| Quotation Model | `lib/shared/models/quotation.dart` |
| Cash Register Model | `lib/shared/models/cash_register.dart` |
| Quotation API | `lib/shared/providers/quotation_api.dart` |
| Cash Register API | `lib/shared/providers/cash_register_api.dart` |
| Quotation List Notifier | `lib/shared/providers/riverpod/quotation_list_notifier.dart` |
| Quotation Detail Notifier | `lib/shared/providers/riverpod/quotation_detail_notifier.dart` |
| Quotation Form Notifier | `lib/shared/providers/riverpod/quotation_form_notifier.dart` |
| Cash Register Notifier | `lib/shared/providers/riverpod/cash_register_notifier.dart` |
| Cash Movements Notifier | `lib/shared/providers/riverpod/cash_movements_notifier.dart` |
| Quotations Page | `lib/features/quotations/pages/quotations_page.dart` |
| Quotation Detail Page | `lib/features/quotations/pages/quotation_detail_page.dart` |
| Create Quotation Page | `lib/features/quotations/pages/create_quotation_page.dart` |
| Cash Register Page | `lib/features/cash_register/pages/cash_register_page.dart` |
| Cash Movements Page | `lib/features/cash_register/pages/cash_movements_page.dart` |

---

**Last Updated**: 2024  
**Version**: 1.0  
**Status**: Production Ready ✅
