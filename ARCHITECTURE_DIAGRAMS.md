# System Architecture Diagram

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Web UI                            │
│  (Pages, Widgets, Forms, Tables, Dialogs)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│   │ Quotations   │  │ Create       │  │ Quotation    │          │
│   │ List Page    │  │ Quotation    │  │ Detail Page  │          │
│   │              │  │ Page         │  │              │          │
│   └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│          │                 │                  │                  │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│   │ Cash Register│  │ Cash         │  │ Filter &     │          │
│   │ Dashboard    │  │ Movements    │  │ Widgets      │          │
│   │              │  │              │  │              │          │
│   └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│          │                 │                  │                  │
└──────────┼─────────────────┼──────────────────┼─────────────────┘
           │                 │                  │
           └─────────────────┼──────────────────┘
                             │
                    ref.watch() & ref.read()
                             │
┌────────────────────────────▼──────────────────────────────────┐
│                  Riverpod State Notifiers                      │
│  (StateNotifier + Family Providers)                            │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌─────────────────────┐  ┌─────────────────────┐            │
│  │ Quotation List      │  │ Quotation Detail    │            │
│  │ Notifier            │  │ Notifier            │            │
│  │ (filtering, paging) │  │ (view, convert)     │            │
│  └──────────┬──────────┘  └──────────┬──────────┘            │
│             │                        │                        │
│  ┌─────────────────────┐  ┌─────────────────────┐            │
│  │ Quotation Form      │  │ Cash Register       │            │
│  │ Notifier            │  │ Notifier            │            │
│  │ (items, discount)   │  │ (open, close, mvts) │            │
│  └──────────┬──────────┘  └──────────┬──────────┘            │
│             │                        │                        │
│  ┌─────────────────────────────────────────────┐             │
│  │ Cash Movements Notifier                     │             │
│  │ (filtering, summary)                        │             │
│  └──────────┬────────────────────────────────┘             │
│             │                                               │
└─────────────┼───────────────────────────────────────────────┘
              │
              │ API calls via ApiService
              │
┌─────────────▼───────────────────────────────────────────────────┐
│                     HTTP API Services                           │
│  (Token injection, error handling)                              │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────────────┐  ┌──────────────────────┐           │
│  │ QuotationApi         │  │ CashRegisterApi      │           │
│  │ • getQuotations()    │  │ • getCurrentCash()   │           │
│  │ • getQuotation()     │  │ • openCashRegister() │           │
│  │ • createQuotation()  │  │ • closeCashRegister()│           │
│  │ • deleteQuotation()  │  │ • getMovements()     │           │
│  │ • convertToOrder()   │  │ • addMovement()      │           │
│  └──────────┬───────────┘  └──────────┬───────────┘           │
│             │                         │                        │
└─────────────┼─────────────────────────┼────────────────────────┘
              │                         │
              └─────────────┬───────────┘
                            │
                      HTTP Requests
                            │
┌───────────────────────────▼────────────────────────────────────┐
│                    Backend API Server                           │
│              (Node.js/Express/Python/etc)                       │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  Quotations Endpoints:                                         │
│  • GET    /api/quotations (filtered)                          │
│  • GET    /api/quotations/:id                                 │
│  • POST   /api/quotations (create)                            │
│  • PUT    /api/quotations/:id (update)                        │
│  • DELETE /api/quotations/:id                                 │
│  • POST   /api/quotations/:id/convert (to order)              │
│                                                                │
│  Cash Register Endpoints:                                      │
│  • GET    /api/cash-registers/current                         │
│  • POST   /api/cash-registers/open                            │
│  • POST   /api/cash-registers/:id/close                       │
│  • GET    /api/cash-registers/movements (filtered)            │
│  • POST   /api/cash-registers/:id/movements (add)             │
│  • GET    /api/cash-registers/movements/by-date               │
│  • GET    /api/cash-registers/:id/summary                     │
│                                                                │
└───────────────────────────────────────────────────────────────┘
                            │
                      Database Queries
                            │
┌───────────────────────────▼────────────────────────────────────┐
│                    Database Server                              │
│          (PostgreSQL/MongoDB/etc)                               │
└───────────────────────────────────────────────────────────────┘
```

## Data Flow - Creating a Quotation

```
User fills form
    ↓
[Create Quotation Page]
    ↓
ref.read(quotationFormProvider.notifier)
    ↓
QuotationFormNotifier
    ├── addItem() → state = state.copyWith(items: [...])
    ├── setDiscountAmount() → state = state.copyWith(discount: x)
    └── submitQuotation() → calls API
    ↓
[API Call]
    ↓
QuotationApi.createQuotation()
    ↓
POST /api/quotations
    ↓
Backend creates record
    ↓
Returns Quotation object
    ↓
[Success]
    ↓
formState.successMessage = 'Created!'
    ↓
Navigate to /quotations
    ↓
[Quotations List Page]
    ↓
ref.read(quotationListProvider.notifier).refreshQuotations()
    ↓
List shows new quotation
```

## Data Flow - Opening Cash Register

```
User inputs opening amount
    ↓
[Cash Register Page]
    ↓
ref.read(cashRegisterProvider.notifier)
    ↓
CashRegisterNotifier.openCash(amount)
    ↓
[API Call]
    ↓
CashRegisterApi.openCashRegister()
    ↓
POST /api/cash-registers/open
    ↓
Backend creates CashRegister record
    ↓
Returns CashRegister object
    ↓
[Success]
    ↓
state = state.copyWith(
  currentCashRegister: newCashRegister,
  isRegistered: true,
)
    ↓
UI updates to show:
    ├── Current cash status
    ├── Opening amount
    ├── Daily summary
    └── Close button
    ↓
User can add movements
```

## State Hierarchy

```
App
  ├── authProvider (token, user)
  ├── storeProvider (current store id)
  ├── themeProvider (dark/light)
  ├── currencyProvider (currency symbol)
  │
  └── Feature States:
      │
      ├── quotationListProvider(storeId)
      │   └── QuotationListState
      │       ├── quotations[]
      │       ├── statusFilter
      │       ├── dateRange
      │       ├── pagination
      │       └── isLoading/error
      │
      ├── quotationDetailProvider(quotationId)
      │   └── QuotationDetailState
      │       ├── quotation
      │       └── isLoading/error
      │
      ├── quotationFormProvider(storeId)
      │   └── QuotationFormState
      │       ├── items[]
      │       ├── discount
      │       ├── notes
      │       └── isLoading/error
      │
      ├── cashRegisterProvider(storeId)
      │   └── CashRegisterState
      │       ├── currentCashRegister
      │       ├── dailyMovements[]
      │       ├── expectedAmount
      │       ├── variance
      │       └── isLoading/error
      │
      └── cashMovementsProvider(cashRegisterId)
          └── CashMovementsState
              ├── movements[]
              ├── typeFilter
              ├── summary{}
              └── isLoading/error
```

## Widget Composition

```
QuotationsPage
  ├── AppBar (with actions)
  ├── QuotationFilterWidget
  │   ├── Status Dropdown
  │   └── DateRange Picker
  ├── ListView
  │   ├── QuotationCardWidget (for each)
  │   │   ├── Status Badge
  │   │   ├── Customer Name
  │   │   ├── Dates
  │   │   ├── Total Amount
  │   │   └── Action Buttons

CreateQuotationPage
  ├── AppBar
  ├── Customer Section
  │   └── TextField (customer name)
  ├── Add Items Section
  │   ├── Product TextField
  │   ├── Quantity + Price
  │   └── Add Button
  ├── Items DataTable
  │   └── DataRow (for each item)
  ├── Discount & Notes
  │   ├── Discount Input
  │   └── Notes TextField
  └── Action Buttons

CashRegisterPage
  ├── AppBar
  ├── CashStatusIndicator
  │   ├── Status Badge
  │   ├── Amount Columns
  │   └── Variance Alert
  ├── Open/Close Section
  │   ├── Amount Input
  │   └── Action Button
  └── Daily Summary
      ├── Income Card
      ├── Outcome Card
      └── Net Card

CashMovementsPage
  ├── AppBar
  ├── Filter Section
  │   ├── Date Picker
  │   └── Type Dropdown
  ├── Summary Cards
  │   ├── Income Card
  │   ├── Outcome Card
  │   └── Net Card
  └── Movement List
      └── CashMovementRowWidget (for each)
          ├── Icon
          ├── Type & Description
          ├── Amount
          └── Time
```

## Provider Dependencies

```
quotationListProvider
  ├── depends on → quotationApiProvider
  ├── depends on → authProvider (via API)
  └── depends on → storeProvider (for family)

quotationDetailProvider
  ├── depends on → quotationApiProvider
  └── depends on → authProvider (via API)

quotationFormProvider
  ├── depends on → quotationApiProvider
  └── depends on → authProvider (via API)

cashRegisterProvider
  ├── depends on → cashRegisterApiProvider
  ├── depends on → authProvider (via API)
  └── depends on → storeProvider (for family)

cashMovementsProvider
  ├── depends on → cashRegisterApiProvider
  └── depends on → authProvider (via API)

quotationApiProvider
  └── depends on → authProvider (token injection)

cashRegisterApiProvider
  └── depends on → authProvider (token injection)
```

## Error Handling Flow

```
User Action
    ↓
Try Block
    ├─ API Call
    ├─ Response Parse
    └─ State Update
    ↓
Success Branch              Catch Branch
    ↓                           ↓
state.isLoading = false    state.error = e.toString()
state.error = null         state.isLoading = false
Show Data                   Show Error Message
                            Show Retry Button
```

## Responsive Design

```
┌──────────────────────────────────────────────────────┐
│                   Desktop (≥1024px)                  │
│  ┌─────────┬──────────────────────────────────────┐  │
│  │ Sidebar │ Main Content Area (wide)             │  │
│  │ Menu    │ • DataTable with all columns         │  │
│  │         │ • Side filters                       │  │
│  │         │ • Multiple columns visible           │  │
│  └─────────┴──────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│                Tablet (600-1024px)                   │
│  ┌────────────────────────────────────────────────┐  │
│  │ Main Content Area (medium)                     │  │
│  │ • DataTable scrollable                         │  │
│  │ • Filters in collapsible panel                 │  │
│  │ • Reduced column visibility                    │  │
│  └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│               Mobile (<600px)                        │
│  ┌────────────────────────────────────────────────┐  │
│  │ Main Content Area (compact)                    │  │
│  │ • Card/List view (not DataTable)               │  │
│  │ • Stack layout                                 │  │
│  │ • Single column                                │  │
│  │ • Bottom sheets for details                    │  │
│  └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

## Technology Stack Visualization

```
                    Flutter Web
                        │
        ┌───────────────┼───────────────┐
        │               │               │
    Riverpod        GoRouter        Material 3
    (State)      (Navigation)         (UI)
        │               │               │
        ├── StateNotifier       ├── Scaffold
        ├── Family Providers    ├── AppBar
        ├── ref.watch()         ├── DataTable2
        └── ref.listen()        ├── Card
                                ├── TextField
                                └── Dialog

                        │
                    ApiService
                    (HTTP Client)
                        │
    ┌───────────────────┼───────────────────┐
    │                   │                   │
QuotationApi    CashRegisterApi         Error Handling
                                        └── Exception
                                        └── Try-Catch
                                        └── State.error
```

---

**This diagram is a complete visual reference of the system architecture.**

Print or bookmark for quick reference during development!
