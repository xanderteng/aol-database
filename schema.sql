-- Buat table category
CREATE TABLE `category` (
    CategoryId INT NOT NULL AUTO_INCREMENT,
    CategoryName VARCHAR(100) NOT NULL,

    PRIMARY KEY (CategoryId),
    UNIQUE KEY UQ_CategoryName (CategoryName)
);

-- Buat table country
CREATE TABLE `country` (
    CountryId INT NOT NULL AUTO_INCREMENT,
    CountryName VARCHAR(100) NOT NULL,

    PRIMARY KEY (CountryId),
    UNIQUE KEY UQ_CountryName (CountryName)
);
-- Buat table customer
CREATE TABLE `customer` (
    `CustomerId`       varchar(20) NOT NULL,
    `CustomerName`     VARCHAR(100) NOT NULL,
    `CustomerEmail`    VARCHAR(100) NOT NULL,
    `CustomerPhone`    VARCHAR(15)  NOT NULL,
    `CustomerAddress`  VARCHAR(150) NOT NULL,
    `CountryId`        INT,

    PRIMARY KEY (`CustomerId`),
    UNIQUE KEY `UQ_CustomerEmail` (`CustomerEmail`),
    UNIQUE KEY `UQ_CustomerPhone` (`CustomerPhone`),
    KEY `IDX_Customer_Country` (`CountryId`),

    CONSTRAINT `FK_Customer_Country`
        FOREIGN KEY (`CountryId`) REFERENCES `country` (`CountryId`)
);

-- Buat table expedition
CREATE TABLE `expedition` (
    `ExpeditionId`    INT NOT NULL AUTO_INCREMENT,
    `ExpeditionName`  VARCHAR(100) NOT NULL,

    PRIMARY KEY (`ExpeditionId`),
    UNIQUE KEY `UQ_ExpeditionName` (`ExpeditionName`)
);


-- Buat table seller
CREATE TABLE `seller` (
    `SellerId`      INT NOT NULL AUTO_INCREMENT,
    `SellerName`    VARCHAR(100) NOT NULL,
    `SellerEmail`   VARCHAR(100) NOT NULL,
    `SellerPhone`   VARCHAR(15) NOT NULL,
    `SellerAddress` VARCHAR(150) NOT NULL,

    PRIMARY KEY (`SellerId`),
    UNIQUE KEY `UQ_SellerEmail` (`SellerEmail`),
    UNIQUE KEY `UQ_SellerPhone` (`SellerPhone`)
);

-- Buat table product
CREATE TABLE `product` (
    `ProductId`          varchar(20) NOT NULL,
    `CategoryId`         INT NOT NULL,
    `ProductName`        VARCHAR(200) NOT NULL,
    `ProductDescription` VARCHAR(200),
    `ProductPrice`       DECIMAL(10,2) NOT NULL,
    `ProductQuantity`    INT NOT NULL DEFAULT 0 CHECK (ProductQuantity >= 0),

    PRIMARY KEY (`ProductId`),
    KEY `IDX_Product_Category` (`CategoryId`),

    CONSTRAINT `FK_Product_Category`
        FOREIGN KEY (`CategoryId`) REFERENCES `category` (`CategoryId`)
);

-- Buat table invoice
CREATE TABLE `invoice` (
    `InvoiceId`     varchar(20) NOT NULL,
    `CustomerId`    varchar(20) NOT NULL,
    `SellerId`      INT NOT NULL,
    `ExpeditionId`  INT,
    `InvoiceDate`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `InvoiceStatus` ENUM('Pending', 'Paid', 'Cancelled', 'Shipped', 'Returned') DEFAULT 'Pending',

    PRIMARY KEY (`InvoiceId`),
    KEY `IDX_Invoice_Customer` (`CustomerId`),
    KEY `IDX_Invoice_Seller` (`SellerId`),
    KEY `IDX_Invoice_Expedition` (`ExpeditionId`),

    CONSTRAINT `FK_Invoice_Customer`
        FOREIGN KEY (`CustomerId`) REFERENCES `customer` (`CustomerId`),

    CONSTRAINT `FK_Invoice_Seller`
        FOREIGN KEY (`SellerId`) REFERENCES `seller` (`SellerId`),

    CONSTRAINT `FK_Invoice_Expedition`
        FOREIGN KEY (`ExpeditionId`) REFERENCES `expedition` (`ExpeditionId`)
);

-- Buat table invoicedetails
CREATE TABLE `invoicedetails` (
    `InvoiceId`   varchar(20) NOT NULL,
    `ProductId`   varchar(20) NOT NULL,
    `Quantity`    INT NOT NULL CHECK (Quantity <> 0),
    `TotalPrice`  DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (`InvoiceId`, `ProductId`),
    KEY `IDX_InvoiceDetails_Product` (`ProductId`),

    CONSTRAINT `FK_InvoiceDetails_Invoice`
        FOREIGN KEY (`InvoiceId`) REFERENCES `invoice` (`InvoiceId`) ON DELETE CASCADE,

    CONSTRAINT `FK_InvoiceDetails_Product`
        FOREIGN KEY (`ProductId`) REFERENCES `product` (`ProductId`)
);

-- Trigger untuk totalPrice berdasarkan historical price
DELIMITER $$

CREATE TRIGGER trg_invoicedetails_before_insert
BEFORE INSERT ON invoicedetails
FOR EACH ROW
BEGIN
    DECLARE price DECIMAL(10,2);

    -- Ambil harga produk saat transaksi (historical price)
    SELECT ProductPrice INTO price
    FROM product
    WHERE ProductId = NEW.ProductId;

    -- Validasi product ID
    IF price IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ProductId tidak ditemukan, tidak dapat menghitung TotalPrice';
    END IF;

    SET NEW.TotalPrice = NEW.Quantity * price;
END $$

DELIMITER ;
