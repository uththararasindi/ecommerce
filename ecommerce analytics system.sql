--create tables
CREATE TABLE Customers (
CustomerID INT IDENTITY(1,1) PRIMARY KEY,
FirstName VARCHAR(100),
LastName VARCHAR(100),
Email VARCHAR(150) UNIQUE NOT NULL,
Phone VARCHAR(20),
CreatedAt DATETIME DEFAULT GETDATE()
);


CREATE TABLE Categories (
CategoryID INT IDENTITY(1,1) PRIMARY KEY,
CategoryName VARCHAR(100) UNIQUE NOT NULL
);


CREATE TABLE Products (
ProductID INT IDENTITY(1,1) PRIMARY KEY,
ProductName VARCHAR(200) NOT NULL,
CategoryID INT NOT NULL,
Price MONEY CHECK (Price >= 0),
Stock INT CHECK (Stock >= 0),
FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);


CREATE TABLE Shippers (
ShipperID INT IDENTITY(1,1) PRIMARY KEY,
ShipperName VARCHAR(150) NOT NULL
);


CREATE TABLE Orders (
OrderID INT IDENTITY(1,1) PRIMARY KEY,
CustomerID INT NOT NULL,
OrderDate DATETIME DEFAULT GETDATE(),
ShipperID INT,
OrderStatus VARCHAR(50) DEFAULT 'Pending',
FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
FOREIGN KEY (ShipperID) REFERENCES Shippers(ShipperID)
);


CREATE TABLE OrderItems (
OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
OrderID INT NOT NULL,
ProductID INT NOT NULL,
Quantity INT CHECK (Quantity > 0),
UnitPrice MONEY CHECK (UnitPrice >= 0),
FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);


CREATE TABLE Payments (
PaymentID INT IDENTITY(1,1) PRIMARY KEY,
OrderID INT NOT NULL,
Amount MONEY CHECK (Amount >= 0),
PaymentMethod VARCHAR(50),
PaymentDate DATETIME DEFAULT GETDATE(),
FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);


CREATE TABLE Reviews (
ReviewID INT IDENTITY(1,1) PRIMARY KEY,
ProductID INT NOT NULL,
CustomerID INT NOT NULL,
Rating INT CHECK (Rating BETWEEN 1 AND 5),
ReviewText VARCHAR(500),
CreatedAt DATETIME DEFAULT GETDATE(),
FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);


CREATE TABLE InventoryLog (
LogID INT IDENTITY(1,1) PRIMARY KEY,
ProductID INT,
OldStock INT,
NewStock INT,
ChangedAt DATETIME DEFAULT GETDATE()
);


CREATE TABLE Cart (
CartID INT IDENTITY(1,1) PRIMARY KEY,
CustomerID INT,
ProductID INT,
Quantity INT,
AddedAt DATETIME DEFAULT GETDATE(),
FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

INSERT INTO Categories (CategoryName) VALUES
('Electronics'),
('Clothing'),
('Books'),
('Home Appliances'),
('Sports');

INSERT INTO Customers (FirstName, LastName, Email, Phone)
VALUES
('John','Doe','john@example.com','7771234'),
('Sara','Lee','sara@example.com','4448234'),
('Nimal','Perera','nimalp@example.com','712345678'),
('Kavindu','Silva','kavindu@example.com','771122334'),
('Mala','Fernando','mala@example.com','775667788');

INSERT INTO Products (ProductName, CategoryID, Price, Stock)
VALUES
('Laptop', 1, 1200, 10),
('Headphones', 1, 200, 50),
('Smartphone', 1, 800, 30),
('T-Shirt', 2, 20, 100),
('Jeans', 2, 45, 80),
('Novel - Mystery', 3, 15, 200),
('Cooker', 4, 150, 25),
('Blender', 4, 60, 40),
('Cricket Bat', 5, 120, 22),
('Football', 5, 35, 55);

INSERT INTO Shippers (ShipperName) VALUES
('DHL'),
('FedEx'),
('Aramex');

INSERT INTO Orders (CustomerID, ShipperID, OrderStatus)
VALUES
(1, 1, 'Completed'),
(2, 2, 'Completed'),
(3, 1, 'Pending'),
(4, 3, 'Completed'),
(5, 2, 'Cancelled');

INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES
(1, 1, 1, 1200), -- Laptop
(1, 2, 2, 200), -- Headphones
(2, 4, 3, 20), -- T-Shirt
(2, 6, 1, 15), -- Novel
(3, 3, 1, 800), -- Smartphone
(3, 9, 1, 120), -- Cricket Bat
(4, 7, 1, 150), -- Cooker
(4, 10, 2, 35), -- Footballs
(5, 5, 1, 45); -- Jeans

INSERT INTO Payments (OrderID, Amount, PaymentMethod)
VALUES
(1, 1600, 'Card'),
(2, 75, 'Cash'),
(4, 220, 'Card');

INSERT INTO Reviews (ProductID, CustomerID, Rating, ReviewText)
VALUES
(1, 1, 5, 'Excellent laptop!'),
(4, 2, 4, 'Good quality T-shirt'),
(6, 3, 5, 'Amazing mystery novel'),
(7, 4, 3, 'Works fine'),
(10, 5, 4, 'Good product for sports');

INSERT INTO Cart (CustomerID, ProductID, Quantity)
VALUES
(1, 3, 1), -- Smartphone
(2, 5, 2), -- Jeans
(3, 8, 1), -- Blender
(4, 10, 1), -- Football
(5, 2, 1); -- Headphones

--logging stock changes by a trigger
CREATE TRIGGER trg_StockChange
ON Products
AFTER UPDATE
AS
BEGIN
INSERT INTO InventoryLog (ProductID, OldStock, NewStock)
SELECT i.ProductID, d.Stock, i.Stock
FROM inserted i
JOIN deleted d ON i.ProductID = d.ProductID
WHERE i.Stock <> d.Stock;
END;

--to calculate the order total by a function
CREATE FUNCTION fn_OrderTotal(@OrderID INT)
RETURNS MONEY
AS
BEGIN
DECLARE @total MONEY;
SELECT @total = SUM(UnitPrice * Quantity)
FROM OrderItems WHERE OrderID=@OrderID;
RETURN @total;
END;

--create new order by a stored procedure
CREATE PROCEDURE sp_CreateOrder
@CustomerID INT,
@ShipperID INT
AS
BEGIN
INSERT INTO Orders (CustomerID, ShipperID) VALUES (@CustomerID, @ShipperID);
SELECT SCOPE_IDENTITY() AS OrderID;
END;

--adding an item to order
CREATE PROCEDURE sp_AddOrderItem
@OrderID INT,
@ProductID INT,
@Qty INT
AS
BEGIN
DECLARE @price MONEY;
SELECT @price = Price FROM Products WHERE ProductID=@ProductID;


INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES (@OrderID, @ProductID, @Qty, @price);
END;

--queries
--Total revenue
SELECT SUM(Amount) AS TotalRevenue FROM Payments;

--Top 5 customers by spend
SELECT c.FirstName, c.LastName, SUM(p.Amount) TotalSpent
FROM Customers c
JOIN Orders o ON c.CustomerID=o.CustomerID
JOIN Payments p ON o.OrderID=p.OrderID
GROUP BY c.FirstName, c.LastName
ORDER BY TotalSpent DESC;

--Monthly revenue trend
SELECT YEAR(PaymentDate) Yr, MONTH(PaymentDate) Mo, SUM(Amount) Revenue
FROM Payments
GROUP BY YEAR(PaymentDate), MONTH(PaymentDate)
ORDER BY Yr, Mo;

--Best-selling products
SELECT p.ProductName, SUM(oi.Quantity) QtySold
FROM OrderItems oi
JOIN Products p ON oi.ProductID=p.ProductID
GROUP BY p.ProductName
ORDER BY QtySold DESC;


--Products low in stock
SELECT * FROM Products WHERE Stock < 10;

--testing the trigger
--this trigger logs stock changes into InventoryLog whenever Products.Stock changes
--first check the current logs
SELECT ProductID, ProductName, Stock 
FROM Products
WHERE ProductID = 1;   -- Example:Laptop
--next update the stock into the trigger log
UPDATE Products
SET Stock = Stock - 2
WHERE ProductID = 1;
--view the trigger output
SELECT * FROM InventoryLog
ORDER BY LogID DESC;

--testing the function
--this function calculates the total for an order from OrderItems
--first pick an order for the testing
SELECT * FROM OrderItems WHERE OrderID = 1;
--use the function
SELECT dbo.fn_OrderTotal(1) AS TotalForOrder1;
--what is expected as the output is (UnitPrice × Quantity) for OrderID = 1

--testing the stored procedure
--this creates a new order and returns the new OrderID
--first run the stored procedure
EXEC sp_CreateOrder 
    @CustomerID = 2,
    @ShipperID = 1;
--now check if an order was added
SELECT TOP 5 * FROM Orders ORDER BY OrderID DESC;

--adds an item to an order and fetches product price automatically
--firstly I used the OrderID returned above, example = 6
EXEC sp_AddOrderItem
    @OrderID = 6,
    @ProductID = 3,   -- Smartphone
    @Qty = 2;
--now verify the insertion
SELECT * FROM OrderItems WHERE OrderID = 6;






