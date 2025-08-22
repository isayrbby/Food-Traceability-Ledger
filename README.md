# 🥗 Food Traceability Ledger

A blockchain-based food traceability system built on Stacks that tracks every step of a meal's journey from farm to table.

## 🌟 Features

- 🚜 **Farm Registration**: Farms can register and create products with batch tracking
- 🚚 **Distribution Tracking**: Complete chain of custody from farm → distributor → restaurant
- ✅ **Quality Control**: Certified inspectors can conduct quality checks at any stage
- 📍 **Location Tracking**: GPS coordinates and temperature monitoring during transfers
- 🔒 **Immutable Records**: All data permanently stored on the Stacks blockchain
- 👥 **Multi-Participant**: Support for farms, distributors, and restaurants

## 🏗️ Contract Architecture

### Participant Types
- **Farm** (`farm`): Creates products and initiates the supply chain
- **Distributor** (`distributor`): Handles logistics and transportation
- **Restaurant** (`restaurant`): Final destination for food products

### Core Data Structures
- **Participants**: Registered entities with certification status
- **Products**: Food items with origin, ownership, and quality data
- **Transfer History**: Complete audit trail of product movement
- **Quality Records**: Inspection results from certified inspectors

## 🚀 Usage Instructions

### 1. Register as a Participant

```clarity
(contract-call? .Food-Traceability-Ledger register-participant "farm" "Green Valley Farm" "123 Farm Road, CA")
```

**Parameters:**
- `participant-type`: `"farm"`, `"distributor"`, or `"restaurant"`
- `name`: Your business name (max 100 chars)
- `location`: Physical address (max 200 chars)

### 2. Get Certified (Contract Owner Only)

```clarity
(contract-call? .Food-Traceability-Ledger certify-participant u1)
```

Only certified participants can conduct quality checks.

### 3. Create a Product (Farms Only)

```clarity
(contract-call? .Food-Traceability-Ledger create-product "Organic Tomatoes" "vegetables" "BATCH-2024-001")
```

**Parameters:**
- `name`: Product name (max 100 chars)
- `category`: Product category (max 50 chars)
- `batch-number`: Unique batch identifier (max 50 chars)

### 4. Transfer Product

```clarity
(contract-call? .Food-Traceability-Ledger transfer-product u1 u2 "delivery" "Fresh delivery to distributor" (some 4) "Main St Warehouse")
```

**Parameters:**
- `product-id`: ID of product to transfer
- `to-participant-id`: Recipient's participant ID
- `transfer-type`: Type of transfer (max 30 chars)
- `notes`: Additional information (max 500 chars)
- `temperature`: Optional temperature in Celsius
- `location`: Transfer location (max 200 chars)

### 5. Conduct Quality Check (Certified Participants Only)

```clarity
(contract-call? .Food-Traceability-Ledger conduct-quality-check u1 u85 "Product shows good freshness" true)
```

**Parameters:**
- `product-id`: Product to inspect
- `quality-score`: Score from 0-100
- `notes`: Inspection notes (max 500 chars)
- `passed`: Boolean indicating if product passed inspection

### 6. Update Product Status

```clarity
(contract-call? .Food-Traceability-Ledger update-product-status u1 "ready")
```

**Valid statuses:** `"processing"`, `"ready"`, `"delivered"`, `"consumed"`

## 📖 Read-Only Functions

### Get Participant Information
```clarity
(contract-call? .Food-Traceability-Ledger get-participant u1)
(contract-call? .Food-Traceability-Ledger get-participant-by-address 'SP1234...)
```

### Get Product Information
```clarity
(contract-call? .Food-Traceability-Ledger get-product u1)
(contract-call? .Food-Traceability-Ledger get-product-history u1 u0)
(contract-call? .Food-Traceability-Ledger get-product-origin u1)
```

### Quality Records
```clarity
(contract-call? .Food-Traceability-Ledger get-quality-record u1 u0)
(contract-call? .Food-Traceability-Ledger get-product-quality-count u1)
```

### Utility Functions
```clarity
(contract-call? .Food-Traceability-Ledger can-transfer-product u1 'SP1234...)
(contract-call? .Food-Traceability-Ledger is-participant-certified u1)
(contract-call? .Food-Traceability-Ledger get-contract-info)
```

## 🔐 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | `ERR_UNAUTHORIZED` | Caller lacks required permissions |
| u101 | `ERR_NOT_FOUND` | Requested item doesn't exist |
| u102 | `ERR_INVALID_PARTICIPANT` | Invalid participant type |
| u103 | `ERR_PRODUCT_EXISTS` | Product already exists |
| u104 | `ERR_INVALID_TRANSFER` | Transfer validation failed |
| u105 | `ERR_ALREADY_REGISTERED` | Participant already registered |
| u106 | `ERR_INVALID_STATUS` | Invalid status value |

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 🏃‍♂️ Development Workflow

1. **Farm Registration**: Register farm and get certified
2. **Product Creation**: Create products with batch numbers
3. **Supply Chain**: Transfer products through distributors
4. **Quality Control**: Conduct inspections at each stage
5. **Final Delivery**: Update status when delivered to restaurants

## 📊 Example Flow

```
🚜 Green Valley Farm creates "Organic Tomatoes" (BATCH-2024-001)
     ↓ Transfer to distributor
🚚 Fresh Foods Dist receives product (temp: 4°C)
     ↓ Quality check (score: 92/100) ✅
     ↓ Transfer to restaurant
🍴 Mario's Restaurant receives for menu preparation
     ↓ Status: "ready" → "consumed"
```

## 📝 License

This project is open source and available under the MIT License.

---

Built with ❤️ on the Stacks blockchain for food safety and transparency.
