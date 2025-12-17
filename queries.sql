-- Query 1: New Product. Add a new, never-before-seen product to the database.
-- Insert kategori jika belum ada
INSERT INTO category (CategoryName)
VALUES ('Computer Accessories')
ON DUPLICATE KEY UPDATE CategoryId = LAST_INSERT_ID(CategoryId);

SET @category_id = LAST_INSERT_ID();

-- Insert product baru (HARUS ada ProductId)
INSERT INTO product (ProductId, CategoryId, ProductName, ProductDescription, ProductPrice)
VALUES ('PRD001', @category_id, 'Wireless Mechanical Keyboard', 'RGB hot-swap wireless keyboard', 950000);


-- Query 2: Customer Order. Write the series of statements required for an existing customer to order two different products in a single transaction.
-- SETTING COLLATION
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;

-- SETUP DATA FRESH 
INSERT INTO seller (SellerName, SellerEmail, SellerPhone, SellerAddress)
VALUES ('Nordic Gadgets', 'sales@nordicgadgets.com', '081888777666', 'Jl. Dingin No. 10');
SET @seller_id = LAST_INSERT_ID();

INSERT INTO expedition (ExpeditionName)
VALUES ('DHL Norway');
SET @expedition_id = LAST_INSERT_ID();

-- SETUP VARIABEL 
SET @invoice_id = '100001'; 	   -- ID Invoice Baru 
SET @customer_id = '12350';        -- Customer Existing: Customer 12350 (Norway)
SET @productA = '10123C';          -- Product Existing: HEARTS WRAPPING TAPE
SET @qtyA = 20;                    -- Pesan 20 pcs
SET @productB = '10124A';          -- Product Existing: SPOTS ON RED BOOKCOVER TAPE
SET @qtyB = 15;                    -- Pesan 15 pcs

-- EKSEKUSI TRANSAKSI
START TRANSACTION;

-- Insert Invoice Header
INSERT INTO invoice (InvoiceId, CustomerId, SellerId, ExpeditionId, InvoiceDate, InvoiceStatus)
VALUES (@invoice_id, @customer_id, @seller_id, @expedition_id, NOW(), 'Pending');

-- Insert Invoice Details
INSERT INTO invoicedetails (InvoiceId, ProductId, Quantity)
VALUES 
(@invoice_id, @productA, @qtyA),
(@invoice_id, @productB, @qtyB);

-- Update Stock 
UPDATE product 
SET ProductQuantity = ProductQuantity - @qtyA 
WHERE ProductId = @productA;

UPDATE product 
SET ProductQuantity = ProductQuantity - @qtyB 
WHERE ProductId = @productB;

COMMIT;

-- CEK HASIL
SELECT * FROM invoicedetails WHERE InvoiceId = @invoice_id;

-- Query 3: Customer Return. Write the statements required to process a return for one of the items from the order you created above.
-- SETTING COLLATION
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;

-- SETTING VARIABE
SET @target_invoice = '100001';   -- Invoice asal yang mau diretur
SET @return_id      = 'C100001';  -- ID Invoice Retur Baru
SET @product_retur  = '10123C';   -- Pilih manual ID Produk yang mau diretur
SET @qty_retur      = -1;         -- Jumlah retur

-- AMBIL DATA OTOMATIS DARI INVOICE ASAL
SELECT CustomerId, SellerId, ExpeditionId 
INTO @cust_id, @sell_id, @exp_id 
FROM invoice 
WHERE InvoiceId = @target_invoice;

-- EKSEKUSI TRANSAKSI RETUR
START TRANSACTION;

-- Buat Invoice Header (Status 'Returned')
INSERT INTO invoice (InvoiceId, CustomerId, SellerId, ExpeditionId, InvoiceDate, InvoiceStatus)
VALUES (@return_id, @cust_id, @sell_id, @exp_id, NOW(), 'Returned');

-- Kembalikan Stok Barang ke Gudang
UPDATE product 
SET ProductQuantity = ProductQuantity - @qty_retur
WHERE ProductId = @product_retur;

-- Catat Detail Retur
INSERT INTO invoicedetails (InvoiceId, ProductId, Quantity)
VALUES (@return_id, @product_retur, @qty_retur);

COMMIT;

-- CEK HASIL
-- Lihat Invoice Retur C100001
SELECT * FROM invoicedetails WHERE InvoiceId = @return_id;
-- Lihat Stok Produk
SELECT ProductId, ProductQuantity FROM product WHERE ProductId = @product_retur;

-- Query 4: Analytical Report. Write a query to find the top 10 customers by total money spent.
SELECT c.CustomerId, c.CustomerName, TopSales.TotalSpent
FROM (
    SELECT i.CustomerId, SUM(id.TotalPrice) AS TotalSpent
    FROM invoice i
    JOIN invoicedetails id ON i.InvoiceId = id.InvoiceId
    WHERE i.InvoiceStatus IN ('Paid', 'Shipped', 'Returned')
      AND i.CustomerId != 'Guest' 
    GROUP BY i.CustomerId
    ORDER BY TotalSpent DESC
    LIMIT 10
) AS TopSales
JOIN customer c ON TopSales.CustomerId = c.CustomerId
ORDER BY TopSales.TotalSpent DESC;

-- Query 5: Analytical Report. Write a query to identify the month with the highest total sales revenue in the year 2011.
SELECT MONTH(i.InvoiceDate) AS MonthNumber, DATE_FORMAT(i.InvoiceDate, '%M') AS MonthName, SUM(id.TotalPrice) AS TotalRevenue
FROM invoice i
JOIN invoicedetails id ON i.InvoiceId = id.InvoiceId
WHERE YEAR(i.InvoiceDate) = 2011
GROUP BY MonthNumber, MonthName
ORDER BY TotalRevenue DESC
LIMIT 1;