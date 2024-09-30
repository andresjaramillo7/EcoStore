-- 1. Tabla de Usuarios (users)
-- Almacena la información de los usuarios, ya sean clientes, administradores o vendedores.
CREATE TABLE users (
    idUser SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    passW VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    roleUser VARCHAR(20) DEFAULT 'customer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	CHECK (roleUser IN ('customer', 'admin', 'vendor'))
);
-- 2. Tabla de Productos (products)
-- Almacena la información de los productos que se venden en la tienda.
CREATE TABLE products (
    idProducts SERIAL PRIMARY KEY,
    nameProducts VARCHAR(255) NOT NULL,
    descriptionProd TEXT,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    stock INT DEFAULT 0,
    vendor_id INT REFERENCES users(idUser) ON DELETE SET NULL, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 3. Tabla de Categorías (categories)
-- Si planeas clasificar los productos en categorías, puedes agregar una tabla de categorías.
CREATE TABLE categories (
    idCategories SERIAL PRIMARY KEY,
    nameCategories VARCHAR(100) UNIQUE NOT NULL,
    descriptionCat TEXT
);
-- 4. Tabla Intermedia de Categorías-Productos (product_categories)
-- Es una tabla de relación muchos a muchos para vincular productos con múltiples categorías.
CREATE TABLE product_categories (
    product_id INT REFERENCES products(idProducts) ON DELETE CASCADE,
    category_id INT REFERENCES categories(idCategories) ON DELETE CASCADE,
    PRIMARY KEY (product_id, category_id)
);
-- 5. Tabla de Carrito (cart_items)
-- Almacena los productos agregados al carrito por un cliente. Este carrito será temporal hasta que el usuario complete la compra.
CREATE TABLE cart_items (
    idCart SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(idUser) ON DELETE CASCADE,
    product_id INT REFERENCES products(idProducts) ON DELETE CASCADE,
    quantity INT NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 6. Tabla de Pedidos (orders)
-- Una vez que el cliente realiza una compra, se crea un pedido en esta tabla.
CREATE TABLE orders (
    idOrder SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(idUser) ON DELETE CASCADE,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20)DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	CHECK (status IN ('pending', 'paid', 'shipped', 'completed', 'cancelled'))
);
-- 7. Tabla de Detalles de Pedidos (order_items)
-- Registra los productos comprados en cada pedido.
CREATE TABLE order_items (
    idOrder_items SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(idOrder) ON DELETE CASCADE,
    product_id INT REFERENCES products(idProducts) ON DELETE CASCADE,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    quantity INT NOT NULL
);
-- 8. Tabla de Direcciones de Envío (shipping_addresses)
-- Almacena las direcciones de envío de los clientes.
CREATE TABLE shipping_addresses (
    idShipping SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(idUser) ON DELETE CASCADE,
    order_id INT REFERENCES orders(idOrder) ON DELETE SET NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    stateAddress VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL
);
-- 9. Tabla de Métodos de Pago (payment_methods)
-- Almacena los métodos de pago de los clientes, por ejemplo, tarjetas de crédito/débito o PayPal.
CREATE TABLE payment_methods (
    idPayMethod SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(idUser) ON DELETE CASCADE,
    provider VARCHAR(100) NOT NULL,  -- Ejemplo: 'Stripe', 'PayPal'
    account_number VARCHAR(50) NOT NULL,  -- Encriptar si es necesario
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 10. Tabla de Pagos (payments)
-- Almacena los detalles de los pagos realizados en los pedidos.
CREATE TABLE payments (
    idPayments SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(idOrder) ON DELETE CASCADE,
    payment_method_id INT REFERENCES payment_methods(idPayMethod) ON DELETE SET NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	CHECK (status IN ('pending', 'completed', 'failed'))
);

-- INDICES
CREATE UNIQUE INDEX idx_cart_user_product ON cart_items(user_id, product_id);
CREATE INDEX idx_order_status ON orders(status);
CREATE UNIQUE INDEX idx_order_product ON order_items(order_id, product_id);
CREATE INDEX idx_shipping_user ON shipping_addresses(user_id);
CREATE INDEX idx_shipping_order ON shipping_addresses(order_id);
CREATE INDEX idx_payment_status ON payments(status);
CREATE UNIQUE INDEX idx_user_account ON payment_methods(user_id, account_number);
CREATE INDEX idx_product_name ON products(nameProducts);

-- TRIGGERS
CREATE OR REPLACE FUNCTION update_product_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_product_timestamp
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_product_timestamp();