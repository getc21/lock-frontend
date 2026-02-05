# Routing Configuration Guide

## Instructions for Adding Quotations and Cash Register Routes

Update your `lib/config/router/app_router.dart` file with the following routes:

```dart
// Add these imports at the top
import 'package:bellezapp_web/features/quotations/pages/quotations_page.dart';
import 'package:bellezapp_web/features/quotations/pages/quotation_detail_page.dart';
import 'package:bellezapp_web/features/quotations/pages/create_quotation_page.dart';
import 'package:bellezapp_web/features/cash_register/pages/cash_register_page.dart';
import 'package:bellezapp_web/features/cash_register/pages/cash_movements_page.dart';

// Add these routes to your GoRouter configuration:

GoRoute(
  path: '/quotations',
  name: 'quotations',
  builder: (context, state) => const QuotationsPage(),
  routes: [
    GoRoute(
      path: 'create',
      name: 'create_quotation',
      builder: (context, state) => const CreateQuotationPage(),
    ),
    GoRoute(
      path: ':id',
      name: 'quotation_detail',
      builder: (context, state) {
        final quotationId = state.pathParameters['id']!;
        return QuotationDetailPage(quotationId: quotationId);
      },
    ),
  ],
),
GoRoute(
  path: '/cash-register',
  name: 'cash_register',
  builder: (context, state) => const CashRegisterPage(),
),
GoRoute(
  path: '/cash-movements',
  name: 'cash_movements',
  builder: (context, state) => const CashMovementsPage(),
),
```

## Navigation Examples

```dart
// Navigate to quotations list
context.go('/quotations');

// Navigate to create quotation
context.go('/quotations/create');

// Navigate to quotation detail
context.go('/quotations/abc123');

// Navigate to cash register
context.go('/cash-register');

// Navigate to cash movements
context.go('/cash-movements');
```

## Menu/Dashboard Integration

Update your dashboard or menu layout to include links to these features:

```dart
ListTile(
  leading: const Icon(Icons.file_copy),
  title: const Text('Cotizaciones'),
  onTap: () => context.go('/quotations'),
),
ListTile(
  leading: const Icon(Icons.account_balance_wallet),
  title: const Text('Caja'),
  onTap: () => context.go('/cash-register'),
),
```

## Provider Setup

Make sure your store provider is properly initialized in your app initialization code. The store ID is required for these features to work:

```dart
ref.watch(storeProvider) // Must return a Store object with an id property
```

## API Endpoints Required

Your backend needs to provide these endpoints:

### Quotations
- `GET /quotations` - List quotations with filters
- `GET /quotations/:id` - Get single quotation
- `POST /quotations` - Create quotation
- `PUT /quotations/:id` - Update quotation
- `DELETE /quotations/:id` - Delete quotation
- `POST /quotations/:id/convert` - Convert to order

### Cash Register
- `GET /cash-registers/current` - Get current cash register
- `POST /cash-registers/open` - Open cash register
- `POST /cash-registers/:id/close` - Close cash register
- `GET /cash-registers/movements` - Get movements
- `POST /cash-registers/:id/movements` - Add movement
- `GET /cash-registers/movements/by-date` - Get movements by date
- `GET /cash-registers/:id/summary` - Get cash summary

## Testing

1. Run your Flutter web app: `flutter run -d chrome`
2. Navigate to `/quotations` to test quotations features
3. Navigate to `/cash-register` to test cash register features
4. Check browser console for any API errors
