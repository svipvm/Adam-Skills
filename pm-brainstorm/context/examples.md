# Usage Examples for PM Brainstorm

## Example 1: E-commerce Platform Planning

### Initial Request
```
User: "I want to build an e-commerce platform with product catalog, shopping cart, and checkout functionality."
```

### Brainstorm Response
```
PM Brainstorm: "That's an exciting project! Let me help you flesh out the requirements.

**Phase 1: Requirement Discovery**

I have some clarifying questions:

1. **Target Audience**: Who are your customers? B2B, B2C, or both?
2. **Scale**: How many products do you plan to have initially? 100? 10,000?
3. **Geographic**: Will you serve customers globally? Any specific regions?
4. **Timeline**: What's your target launch date?

For now, let me outline what we'll cover:

## Core Features Brainstorm

### Product Catalog
- Product listing with filters (category, price, rating)
- Product detail pages with images, description, reviews
- Search functionality
- Inventory management

### Shopping Cart
- Add/remove items
- Quantity adjustment
- Price calculation with taxes and discounts
- Save cart for later

### Checkout Flow
- Guest checkout vs. account checkout
- Multiple payment methods
- Address management
- Order confirmation

---

Should we dive deeper into any of these areas? And what's most important for your MVP?"
```

## Example 2: Technical Architecture Discussion

### After requirements are clear
```
PM Brainstorm: "Based on your requirements for a mid-sized e-commerce platform, here's my technical architecture recommendation:

## Frontend Architecture

### Recommended Stack
- **Framework**: Next.js (React) - Great for SEO, SSR support
- **State Management**: Zustand for cart/user state
- **UI Library**: Tailwind CSS + shadcn/ui
- **Styling**: CSS Modules for component-scoped styles

### Component Architecture
```
components/
├── common/          # Buttons, inputs, cards
├── product/         # ProductCard, ProductGrid, ProductDetail
├── cart/            # CartItem, CartSummary, CartDrawer
├── checkout/        # AddressForm, PaymentSelector, OrderReview
└── layout/          # Header, Footer, Navigation
```

## Backend Architecture

### Recommended Stack
- **API**: REST with OpenAPI spec (or GraphQL if needed)
- **Framework**: Node.js/Express or NestJS
- **Database**: PostgreSQL (relational data + complex queries)
- **Caching**: Redis for sessions and hot data
- **Queue**: Bull for async jobs (emails, notifications)

### API Design
```
POST   /api/products          # Create product
GET    /api/products          # List products (paginated)
GET    /api/products/:id      # Get product details
PUT    /api/products/:id      # Update product
DELETE /api/products/:id      # Delete product

POST   /api/cart              # Add to cart
GET    /api/cart              # Get cart
PUT    /api/cart/items/:id    # Update quantity
DELETE /api/cart/items/:id    # Remove item

POST   /api/orders            # Create order
GET    /api/orders            # List orders
GET    /api/orders/:id        # Get order details
```

## Frontend-Backend Decoupling

### API Contract (OpenAPI)
- Clear request/response schemas
- Error response definitions
- Versioning strategy (/api/v1/)

### Interface Design
- TypeScript interfaces shared via npm package
- API client generated from OpenAPI spec

---

What aspects would you like to explore further?"
```

## Example 3: Testing Strategy

### Discussion
```
PM Brainstorm: "Now let's talk about testing to ensure your platform is stable and reliable.

## Testing Pyramid for E-commerce

```
        /\
       /  \      E2E: 5-10 tests
      /----\     Critical user flows
     /      \    Integration: 20-30 tests
    /--------\   API contracts, database
   /          \  Unit: 100+ tests
  /____________\ Components, utilities
```

## Test Coverage Targets

| Layer | Target Coverage | Tools |
|-------|-----------------|-------|
| Unit Tests | 80% | Jest, React Testing Library |
| Integration | 70% | Supertest, Testing Library |
| E2E | Critical paths | Playwright |

## Test Scenarios

### Unit Tests
- Product price calculation
- Cart total with discounts
- Tax calculation
- Form validation

### Integration Tests
- Product CRUD operations
- Cart operations
- Order creation flow

### E2E Tests
- Complete purchase flow
- User registration → product search → checkout
- Error handling (payment failure, out of stock)

---

Are you following TDD or will tests be added after implementation? What's your CI/CD setup?"
```

## Example 4: Docker Deployment

### Discussion
```
PM Brainstorm: "Finally, let's ensure your application is containerized and ready for deployment.

## Docker Architecture

```
┌─────────────────────────────────────────┐
│                  nginx                  │
│           (reverse proxy)               │
└────────┬────────────────┬───────────────┘
         │                │
    ┌────▼────┐      ┌────▼────┐
    │ frontend │      │  backend │
    │  (Next)  │      │  (Node)  │
    └────┬────┘      └────┬────┘
         │                │
    ┌────▼────────────────▼────┐
    │         postgres         │
    │         redis            │
    └─────────────────────────┘
```

## Dockerfile Best Practices Applied

### Backend Dockerfile
```dockerfile
# Multi-stage build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:3000/health || exit 1
CMD ["node", "dist/main.js"]
```

### Security Considerations
- ✅ Non-root user (node)
- ✅ Multi-stage build (smaller image)
- ✅ Health check endpoint
- ✅ Alpine base (minimal attack surface)
- ✅ No secrets in image

## Docker Compose for Development
```yaml
services:
  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgres://user:pass@db:5432/shop
    volumes:
      - ./backend:/app
      - /app/node_modules
    depends_on:
      - db
      - redis

  frontend:
    build: ./frontend
    ports:
      - "3001:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules

  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

volumes:
  postgres_data:
```

---

Do you have a preferred cloud provider? What about CI/CD pipeline for Docker?"
```

## Example 5: Design Patterns Application

### Discussion
```
PM Brainstorm: "Let me show you where design patterns can improve your codebase:

## Pattern Recommendations

### 1. Repository Pattern (Data Access)
```typescript
interface ProductRepository {
  findById(id: string): Promise<Product>;
  findAll(filters: ProductFilters): Promise<Product[]>;
  create(product: CreateProductDTO): Promise<Product>;
  update(id: string, data: UpdateProductDTO): Promise<Product>;
  delete(id: string): Promise<void>;
}

// Allows easy switching between DB implementations
// Easy to add caching layer
```

### 2. Strategy Pattern (Payment Processing)
```typescript
interface PaymentStrategy {
  process(amount: number, details: PaymentDetails): Promise<PaymentResult>;
}

class CreditCardStrategy implements PaymentStrategy { ... }
class PayPalStrategy implements PaymentStrategy { ... }
class CryptoStrategy implements PaymentStrategy { ... }

// Easy to add new payment methods
// No if/else chains
```

### 3. Observer Pattern (Event System)
```typescript
class OrderEvents extends EventEmitter {
  onOrderCreated(callback: (order: Order) => void);
  onPaymentProcessed(callback: (payment: Payment) => void);
  onOrderShipped(callback: (order: Order) => void);
}

// Decouple order processing from notifications, analytics, etc.
```

### 4. Adapter Pattern (External APIs)
```typescript
interface PaymentGateway {
  charge(amount: number): Promise<ChargeResult>;
}

class StripeAdapter implements PaymentGateway { ... }
class SquareAdapter implements PaymentGateway { ... }

// Unified interface for different providers
```

---

Which modules would benefit most from these patterns?"
```

## Example 6: Risk Assessment

### Discussion
```
PM Brainstorm: "Let me identify potential risks and mitigation strategies:

## Risk Assessment Matrix

| Risk | Impact | Probability | Score | Mitigation |
|------|--------|-------------|-------|------------|
| Payment integration failure | 5 | 2 | 10 | Multiple payment providers |
| Performance at scale | 4 | 3 | 12 | Load testing, caching strategy |
| Security vulnerabilities | 5 | 2 | 10 | Security audit, penetration testing |
| Third-party API downtime | 3 | 3 | 9 | Fallback mechanisms, circuit breaker |
| Database scalability | 4 | 2 | 8 | Sharding strategy, read replicas |
| Team skill gaps | 3 | 2 | 6 | Training, pair programming |

## High Priority Mitigations

### 1. Payment Integration
- Implement circuit breaker pattern
- Have fallback provider ready
- Queue failed transactions for retry

### 2. Performance
- Implement Redis caching
- CDN for static assets
- Database query optimization

### 3. Security
- Regular dependency updates
- OWASP top 10 compliance
- Rate limiting on APIs

---

Are there any specific concerns you'd like to address first?"
```
