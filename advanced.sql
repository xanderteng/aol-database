-- Trigger: Create a trigger that automatically updates the inventory level of a product whenever a transaction (sale or return) involving that product is recorded
DELIMITER $$

CREATE TRIGGER trg_update_product_inventory
AFTER INSERT ON invoicedetails
FOR EACH ROW
BEGIN
    -- Kurangi stok saat penjualan (Quantity > 0)
    -- Tambah stok saat retur (Quantity < 0)
    UPDATE product
    SET ProductQuantity = ProductQuantity - NEW.Quantity
    WHERE ProductId = NEW.ProductId;
END $$

DELIMITER ;

-- Stored Procedure: Create a stored procedure named `GetCustomerInvoiceHistory` that accepts a `CustomerID` as input and returns a complete list of all invoices (including the date and total value) belonging to that customer.
DELIMITER $$

CREATE PROCEDURE GetCustomerInvoiceHistory (
    IN pCustomerId VARCHAR(20)
)
BEGIN
    SELECT 
        i.InvoiceId,
        i.InvoiceDate,
        i.InvoiceStatus,
        SUM(id.TotalPrice) AS TotalInvoiceValue
    FROM invoice i
    JOIN invoicedetails id
        ON i.InvoiceId = id.InvoiceId
    WHERE i.CustomerId = pCustomerId
    GROUP BY 
        i.InvoiceId,
        i.InvoiceDate,
        i.InvoiceStatus
    ORDER BY i.InvoiceDate DESC;
END $$

DELIMITER ;