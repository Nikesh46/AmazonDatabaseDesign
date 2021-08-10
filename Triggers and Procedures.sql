-- ==============================================
-- Authors - NAMITHA MYSORE SHESHADRI(NMS190006),  NIKESH MANJUNATH (NXM190054), SAHANA SUBRAMANYAM(SXS200210)
-- Description - Amazon Database Design with ER Models, Relational Schema,  Normalisations, Tabels, PL/SQL
-- ===============================================




CREATE TABLE WISHLIST (
  wishlistid       char(9), 
  wishlistname     varchar(25),
  customerid       char(9) not null,
  primary key (wishlistid)
);

CREATE TABLE WISHLIST_PRODUCTS(
  wishlistid       char(9), 
  productid        char(9),
  primary key (wishlistid,productid)
);

CREATE TABLE SELLER(
  sellerid       char(9),
  sellername     varchar(25) not null,
  selleraddr    varchar(250),
  descrption    varchar(250),
  rating        char(1),
  primary key (sellerid)
);

CREATE TABLE PROD_SALE(
  sellerid        char(9), 
  productid        char(9),
  primary key (sellerid,productid)
);


CREATE TABLE ORDERS(
  orderid           char(9),
  order_status      varchar(25),
  order_cost      double,
  invoice         varchar(250),
  payment_info      char(250),
  customerid        char(9) not null,
  cartid          char(9),
  primary key (orderid)
);


CREATE TABLE DELIVERY(
  orderid            char(9),
  companyid         char(9),
  shippingid         char(9) not null,
  shipping_addr      varchar(250),
  shipping_date      date,
  dispatch_date      date,
  primary key (orderid, companyid),
  unique(shippingid)
);


CREATE TABLE CART (
  cartid           char(9),
  cost             double,
  customerid       char(9) not null, 
  primary key (cartid),
  unique (customerid)
);


CREATE TABLE SHIPPING_COMPANY (
  companyid          char(9), 
  company_name       varchar(25) not null,
  primary key (companyid)
);


CREATE TABLE WAREHOUSE (
  warehouseid           char(9),
  warehouse_name        varchar(25) not null,
  warehouse_location    varchar(250),
  primary key (warehouseid)
);



CREATE TABLE PROD_CART (
  cartid                char(9),
  productid             char(9), 
  per_item_quantity     integer,
  primary key (cartid,productid)
);


CREATE TABLE PROD_WAREHOUSE (
  warehouseid            char(9),
  productid              char(9),
  number_of_products     integer,
  primary key (warehouseid,productid)
);

CREATE TABLE CUSTOMER (
  customerid             char(9),
  customer_name          varchar(50) not null,
  phone_number           numeric(10),
  email                  varchar(50),
  sex                    varchar(20),
  age                    integer,
  primary key (customerid)
);


CREATE TABLE CUSTOMER_ADDRESS (
  customerid             char(9),
  address                varchar(50),
  primary key (customerid,address)
);


CREATE TABLE CUSTOMER_PAYMENT (
  customerid             char(9),
  payment_mode           varchar(50) default 9999,
  primary key (customerid,payment_mode)
);


CREATE TABLE PRODUCT (
  productid              char(9),
  product_name            varchar(50) not null,
  price                  double not null,
  customer_q_a           varchar(200),
  category               varchar(50),
  product_description    varchar(100),
  quantity               integer,
  primary key (productid)
);


CREATE TABLE REVIEW (
  reviewid               char(9),
  rating                 float,
  productid              char(9) not null,
  customerid             char(9) not null,
  primary key (reviewid)
);



TRIGGERED ACTIONS ON FOREIGN KEYS:

ALTER TABLE prod_warehouse ADD CONSTRAINT pwwid FOREIGN KEY(warehouseid) REFERENCES warehouse(warehouseid) ON DELETE CASCADE;  

ALTER TABLE prod_cart ADD CONSTRAINT pcid FOREIGN KEY(cartid) REFERENCES cart(cartid) ON DELETE CASCADE;

ALTER TABLE prod_cart ADD CONSTRAINT pcpid FOREIGN KEY(productid) REFERENCES product(productid) ON DELETE CASCADE; 

ALTER TABLE prod_warehouse ADD CONSTRAINT pwpid FOREIGN KEY(productid) REFERENCES product(productid) ON DELETE CASCADE;

ALTER TABLE cart ADD CONSTRAINT ccustid FOREIGN KEY(customerid) REFERENCES customer(customerid) ON DELETE CASCADE; 

ALTER TABLE orders ADD CONSTRAINT ocustid FOREIGN KEY(customerid) REFERENCES customer(customerid) ON DELETE CASCADE;  

ALTER TABLE orders ADD CONSTRAINT ocid FOREIGN KEY(cartid) REFERENCES cart(cartid) ON DELETE CASCADE;

ALTER TABLE delivery ADD CONSTRAINT doid FOREIGN KEY(orderid) REFERENCES orders(orderid) ON DELETE CASCADE;  

ALTER TABLE delivery ADD CONSTRAINT dcompid FOREIGN KEY(companyid) REFERENCES shipping_company(companyid) ON DELETE CASCADE;

ALTER TABLE customer_address ADD CONSTRAINT cacustid FOREIGN KEY(customerid) REFERENCES customer(customerid) ON DELETE CASCADE; 

ALTER TABLE customer_payment ADD CONSTRAINT cpcustid FOREIGN KEY(customerid) REFERENCES customer(customerid) ON DELETE CASCADE;

ALTER TABLE wishlist ADD CONSTRAINT wcustid FOREIGN KEY(customerid) REFERENCES customer(customerid) ON DELETE CASCADE; 

ALTER TABLE wishlist_products ADD CONSTRAINT wpwid FOREIGN KEY(wishlistid) REFERENCES wishlist(wishlistid) ON DELETE CASCADE;  

ALTER TABLE wishlist_products ADD CONSTRAINT wppid FOREIGN KEY(productid) REFERENCES product(productid) ON DELETE CASCADE;

ALTER TABLE review ADD CONSTRAINT rpid FOREIGN KEY(productid) REFERENCES product(productid) ON DELETE CASCADE;  

ALTER TABLE review ADD CONSTRAINT rcustid FOREIGN KEY(customerid) REFERENCES customer(customerid) ON DELETE CASCADE;

ALTER TABLE prod_sale ADD CONSTRAINT pspid FOREIGN KEY(productid) REFERENCES product(productid) ON DELETE CASCADE; 

ALTER TABLE prod_sale ADD CONSTRAINT pssid FOREIGN KEY(sellerid) REFERENCES seller(sellerid) ON DELETE CASCADE; 





/* TRIGGERS */
/* Update Cost on CART table after UPDATE (of Per_Item_Quanity) on PROD_CART table. */
CREATE TRIGGER cart_cost
  AFTER UPDATE OF per_item_quanity, productid ON prod_cart
  FOR EACH ROW
DECLARE
    qty_diff      INT;
    product_price INT;
BEGIN
    /* assume that Per_Item_Quanity and productid are non-null fields */
    qty_diff := :NEW.per_item_quanity - :OLD.per_item_quanity;

    IF ( UPDATING
         AND :old.productid = :new.productid
         AND :old.per_item_quanity != :new.per_item_quanity ) THEN
      SELECT price
      INTO   product_price
      FROM   product
      WHERE  productid = NEW.productid;

      UPDATE CART
      SET    cost = cost + ( qty_diff * product_price )
      WHERE  cartid = :new.cartid;
    END IF;
END; 





/* Trigger to notify when wishlist item is in stock i.e., the item quantity is updated to a value greater than zero */
CREATE OR REPLACE TRIGGER wishlist_item_available 
AFTER UPDATE OF quantity
ON product FOR EACH ROW 
DECLARE wishlistid_value NUMBER;
wishlistname VARCHAR(25);
BEGIN
  IF (:Old.quantity = 0
    AND
    :NEW.quantity > 0)
    THEN SELECT w.wishlistid
    INTO   wishlistid_value
    FROM   wishlist           w,
           wishlist_products  wp,
           product            p
    WHERE  wp.productid = p.productid
    AND wp.wishlistid = w.wishlistid; 
    dbms_output.put_line('Wishlist : '
                  || :wishlistId_value
                  || ' is in Stock');
END IF;
  
END;



/* STORED PROCEDURES */

/* Procedure to change the selling price of the product. */
CREATE OR REPLACE PROCEDURE Update_price (productid IN PRODUCT.productid%TYPE, newprice INT) AS

thisproduct PRODUCT%ROWTYPE;

CURSOR prod_price IS SELECT * FROM PRODUCT;

BEGIN
  OPEN prod_price;
  LOOP
    FETCH prod_price INTO thisproduct;
    EXIT WHEN (prod_price%NOTFOUND);

    UPDATE PRODUCT SET price=newprice WHERE productid=productid; dbms_output.Put_line (' Price has been changed');

  END LOOP;
  CLOSE prod_price;
END;



/* Procedure to view the order history of a particular customer */
CREATE OR REPLACE PROCEDURE Order_history(cid IN ORDERS.customerid%TYPE) AS 
 
min_order float;
max_order float;
thisOrder ORDERS%ROWTYPE;

CURSOR order_details IS
SELECT * FROM ORDERS WHERE cid=customerid;

BEGIN
select min(Order_cost), max(Order_cost) into min_order, max_order from ORDERS;

OPEN order_details;
dbms_output.put_line( 'Here are the details of the orders the customer ' || cid || ' has ordered : ');
LOOP
  FETCH order_details INTO thisOrder;
  EXIT WHEN (order_details%NOTFOUND);

  dbms_output.put_line( ' OrderID : ' || thisOrder.OrderID);
  dbms_output.put_line( ' Total Cost : ' || thisOrder.Order_cost);
  dbms_output.put_line( ' Order Date : ' || thisOrder.Order_date);
  dbms_output.put_line( ' Invoice : ' || thisOrder.Invoice);
  dbms_output.put_line( ' Payment Details : ' || thisOrder.Payment_info);

END LOOP;
CLOSE order_details;

dbms_output.put_line( ' Most expensive order' || max_order);
dbms_output.put_line( ' Most inexpensive order' || min_order);

END;

