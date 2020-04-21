DROP TABLE IF EXISTS Promotion CASCADE;
DROP TABLE IF EXISTS FDSpromo CASCADE;
DROP TABLE IF EXISTS Restaurants CASCADE;
DROP TABLE IF EXISTS Restpromo CASCADE;
DROP TABLE IF EXISTS Categories CASCADE;
DROP TABLE IF EXISTS Food CASCADE;
DROP TABLE IF EXISTS PaymentOption CASCADE;
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS FromMenu CASCADE;
DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS FDSManagers CASCADE;
DROP TABLE IF EXISTS RestaurantStaff CASCADE;
DROP TABLE IF EXISTS Place CASCADE;
DROP TABLE IF EXISTS DeliveryRiders CASCADE;
DROP TABLE IF EXISTS PartTime CASCADE;
DROP TABLE IF EXISTS FullTime CASCADE;
DROP TABLE IF EXISTS WorkingDays CASCADE;
DROP TABLE IF EXISTS ShiftOptions CASCADE;
DROP TABLE IF EXISTS WorkingWeeks CASCADE;
DROP TABLE IF EXISTS Delivers CASCADE; 

CREATE TABLE Promotion (
    promoID     INTEGER GENERATED ALWAYS AS IDENTITY,
    startDate   DATE NOT NULL,
    endDate     DATE NOT NULL,
	startTime 	TIME,
	endTime		TIME,
    discPerc    NUMERIC check(discPerc > 0) DEFAULT NULL,
    discAmt     NUMERIC check(discAmt > 0) DEFAULT NULL,
	type    	VARCHAR(255) NOT NULL CHECK (type in ('FDSpromo', 'Restpromo')),
	PRIMARY KEY (promoID)
);


CREATE TABLE FDSpromo (
    promoID     INTEGER,
    PRIMARY KEY (promoID),
    FOREIGN KEY (promoID) REFERENCES Promotion(promoID) ON DELETE CASCADE
);

CREATE TABLE Restaurants ( 
	restaurantID    INTEGER GENERATED ALWAYS AS IDENTITY,
	name            VARCHAR(100)         NOT NULL,
	location        VARCHAR(255)         NOT NUll,
	minThreshold    INTEGER DEFAULT '0'  NOT NULL,
	PRIMARY KEY (RestaurantID)
);

CREATE TABLE Restpromo (
    promoID     INT, 
    restID      INT NOT NULL,
    PRIMARY KEY (promoID),
    FOREIGN KEY (promoID) REFERENCES Promotion(promoID) ON DELETE CASCADE,
    FOREIGN KEY (restID) REFERENCES Restaurants(restaurantID) ON DELETE CASCADE
);

CREATE TABLE Categories (
	category    VARCHAR(100),
	PRIMARY KEY (category)
);

CREATE TABLE Food ( --availability removed
	foodName        VARCHAR(100)         NOT NULL,
	price           NUMERIC              NOT NULL CHECK (price > 0),
	dailyLimit      INTEGER DEFAULT '50' NOT NULL,
	RestaurantID    INTEGER,
	category        VARCHAR(255)		 NOT NULL,
	PRIMARY KEY (RestaurantID, foodName),
	FOREIGN KEY (RestaurantID) REFERENCES Restaurants (RestaurantID) ON DELETE CASCADE,
	FOREIGN KEY	(category) REFERENCES Categories (category)
);

CREATE TABLE PaymentOption (
    payOption   VARCHAR(100),
    PRIMARY KEY (payOption)
);

CREATE TABLE Orders (
	orderID             INT GENERATED ALWAYS AS IDENTITY,
	deliveryFee         INTEGER                           NOT NULL DEFAULT 4,
	cost                NUMERIC      DEFAULT 0            NOT NULL,
	location            VARCHAR(255)                      NOT NULL,
	date                DATE DEFAULT CURRENT_DATE         NOT NULL,
	payOption	    VARCHAR(50)			    		  NOT NULL,
	area                CHAR (1)					  NOT NULL CHECK (area in ('N','S','E','W')),
	orderStatus         VARCHAR(50) DEFAULT 'Pending'     NOT NULL CHECK (orderStatus in ('Pending','Confirmed','Completed','Failed')),
	deliveryDuration    VARCHAR(50)  				  NOT NULL,
	timeOrderPlace      TIME DEFAULT CURRENT_TIME,
	timeDepartToRest    TIME,
	timeArriveRest      TIME,
	timeDepartFromRest  TIME,
	timeOrderDelivered  TIME,
	PRIMARY KEY (orderID),
	FOREIGN KEY (payOption) REFERENCES PaymentOption (payOption)
);

CREATE TABLE FromMenu (
	promoID     INT,
	quantity        INTEGER      NOT NULL,
	orderID         INT         NOT NULL,
	restaurantID    INTEGER         NOT NULL,
	foodName        VARCHAR(100)    NOT NULL,
    hide BOOLEAN DEFAULT FALSE NOT NULL,
	PRIMARY KEY (restaurantID,foodName,orderID),
	FOREIGN KEY (promoID) REFERENCES Restpromo (promoID),
	FOREIGN KEY (orderID) REFERENCES Orders (orderID),
	FOREIGN KEY (restaurantID, foodName) REFERENCES Food (restaurantID, foodName) ON DELETE CASCADE
);

CREATE TABLE Users (
	uid         INT GENERATED ALWAYS AS IDENTITY,
	name        VARCHAR(255)     NOT NULL,
	username    VARCHAR(255)     NOT NULL,
	password    VARCHAR(255)     NOT NULL,
	type    VARCHAR(255) NOT NULL CHECK (type in ('Customers', 'FDSManagers', 'RestaurantStaff', 'DeliveryRiders')), 
	PRIMARY KEY (uid)
);

CREATE TABLE Customers (
	uid         INTEGER,
	rewardPts   INTEGER DEFAULT '0' NOT NULL,
	signUpDate  DATE    DEFAULT CURRENT_DATE NOT NULL,
	cardDetails VARCHAR(255),
	PRIMARY KEY (uid),
	FOREIGN KEY (uid) REFERENCES Users(uid) ON DELETE CASCADE
);

CREATE TABLE FDSManagers (
	uid         INTEGER,
	PRIMARY KEY (uid),
	FOREIGN KEY (uid) REFERENCES Users ON DELETE CASCADE
);

CREATE TABLE RestaurantStaff (
	uid         INTEGER,
	restaurantID INTEGER NOT NULL, 
	PRIMARY KEY (uid),
	FOREIGN KEY (uid, restaurantID) REFERENCES Users(uid, restaurantID) ON DELETE CASCADE
);

CREATE TABLE DeliveryRiders (
    uid             INTEGER PRIMARY KEY,
	baseDeliveryFee NUMERIC NOT NULL DEFAULT 2,
	availability BOOLEAN DEFAULT TRUE,  -- free by default
	type    VARCHAR(255)  NOT NULL CHECK (type in ('FullTime', 'PartTime')),
    FOREIGN KEY (uid, type) REFERENCES Users(uid, riderType) ON DELETE CASCADE
);

CREATE TABLE Place (
	uid            INT,
	orderid        INT,  
	review         VARCHAR(255)     NOT NULL,
	star           INTEGER      DEFAULT NULL CHECK (star >= 0 AND star <= 5), 
	promoid        INT,
	PRIMARY KEY (orderid),
	FOREIGN KEY (uid) REFERENCES Customers ON DELETE CASCADE,
	FOREIGN KEY (promoID) REFERENCES Promotion(promoID) ON DELETE CASCADE,
	FOREIGN KEY (orderid) REFERENCES Orders ON DELETE CASCADE
);

CREATE TABLE PartTime (
	uid            INTEGER PRIMARY KEY,
	weeklyBasePay   NUMERIC NOT NULL DEFAULT 100, /* $10 times minimum 10 hours in each WWS*/
    FOREIGN KEY (uid) REFERENCES DeliveryRiders(uid) ON DELETE CASCADE
);

CREATE TABLE FullTime (
	uid              INTEGER PRIMARY KEY,
	monthlyBasePay   INTEGER NOT NULL DEFAULT 1800,
    FOREIGN KEY (uid) REFERENCES DeliveryRiders(uid) ON DELETE CASCADE
);

CREATE TABLE  WorkingDays ( -- Part Timer
	uid             INTEGER, 
	workDate        DATE NOT NULL,
	intervalStart   TIME NOT NULL,
	intervalEnd     TIME NOT NULL,
	numCompleted    INTEGER DEFAULT 0,
	PRIMARY KEY (uid, workDate, intervalStart, intervalEnd),--
	FOREIGN KEY (uid) REFERENCES PartTime(uid) ON DELETE CASCADE,
	CHECK (intervalEnd > intervalStart),
	CHECK (intervalStart>='10:00:00' and intervalEnd<='22:00:00'),
	CHECK (CAST(CONCAT(CAST(EXTRACT(HOUR from intervalStart) AS VARCHAR),':00:00') AS TIME)=intervalStart),
	CHECK (CAST(CONCAT(CAST(EXTRACT(HOUR from intervalEnd) AS VARCHAR),':00:00') AS TIME)=intervalEnd),
	CHECK (EXTRACT(HOUR FROM intervalEnd) - EXTRACT(HOUR FROM intervalStart)<=4)
);

CREATE TABLE ShiftOptions (
	shiftID         INTEGER, 
	shiftDetail1    VARCHAR(30) NOT NULL,
	shiftDetail2    VARCHAR(30) NOT NULL,
	PRIMARY KEY (shiftID)
);

CREATE TABLE  WorkingWeeks (-- Full Timer
	uid             INTEGER,
	workDate        DATE NOT NULL,
	shiftID         INTEGER NOT NULL,
	numCompleted    INTEGER DEFAULT 0,
	PRIMARY KEY (uid, workDate),
	FOREIGN KEY (uid) REFERENCES FullTime ON DELETE CASCADE,
	FOREIGN KEY (shiftID) REFERENCES ShiftOptions(shiftID)
);


CREATE TABLE Delivers (
    orderID         INTEGER,
    uid             INTEGER,
    rating          INTEGER      DEFAULT NULL CHECK (rating >= 0 AND rating <= 5), 
    PRIMARY KEY (orderID),
    FOREIGN KEY (orderID) REFERENCES Orders(orderID) ON DELETE CASCADE,
    FOREIGN KEY (uid) REFERENCES DeliveryRiders(uid) ON DELETE CASCADE
);


/*check availability*/ --problem
CREATE OR REPLACE FUNCTION check_availability()
RETURNS TRIGGER AS $$
DECLARE currAvailability INTEGER;
DECLARE qtyOrdered INTEGER;

BEGIN
    qtyOrdered := NEW.quantity;

    SELECT dailyLimit into currAvailability 
    FROM Food 
    WHERE Food.foodname = NEW.foodName
    AND Food.restaurantID = NEW.restaurantID;

    IF NEW.quantity > currAvailability THEN
        RAISE NOTICE 'Exceed Daily Limit';
        UPDATE Orders SET orderStatus = 'Failed' WHERE Orders.orderID = NEW.orderID;
        RETURN NULL; -- abort inserted row
    ELSE 
        UPDATE Orders SET orderStatus = 'Confirmed' WHERE Orders.orderID = NEW.orderID;
        UPDATE Food SET dailyLimit = dailyLimit - qtyOrdered WHERE Food.foodname = NEW.foodName AND Food.restaurantID = NEW.restaurantID;
        
        RAISE NOTICE 'Order Confirmed';
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER availability_trigger
BEFORE INSERT ON FromMenu
FOR EACH ROW
EXECUTE PROCEDURE check_availability();


/*check whether order placed during operational hours*/
CREATE OR REPLACE FUNCTION check_operational_hours() --after operating hours, insertion continuessss
RETURNS TRIGGER AS $$
DECLARE currHour NUMERIC;
DECLARE openingHour NUMERIC;
DECLARE closingHour NUMERIC;

BEGIN
    openingHour := 10; --10am
    closingHour := 22; --10pm
    
    SELECT EXTRACT(HOUR from timeOrderPlace) INTO currHour
    FROM Orders
    WHERE NEW.orderID = Orders.OrderID;

    IF currHour < openingHour THEN
        UPDATE Orders SET orderStatus = 'Failed' WHERE NEW.orderID = Orders.OrderID;
        RAISE NOTICE 'Not within Opening Hours';
        RETURN NULL; 
    ELSIF currHour >= closingHour THEN
        UPDATE Orders SET orderStatus = 'Failed' WHERE NEW.orderID = Orders.OrderID; 
        RAISE NOTICE 'Not within Opening Hours';
        RETURN NULL; --RETURN NULL instead of RETURN NEW to just abort the inserted row silently without raising an exception and without rolling anything back.
    ELSE 
        RAISE NOTICE 'Within Opening Hours';
        RETURN NEW; 
    END IF;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER operating_trigger
BEFORE INSERT ON Place
FOR EACH ROW
EXECUTE PROCEDURE check_operational_hours();


/*ISA check for delivery riders*/
CREATE OR REPLACE FUNCTION check_riders()
RETURNS TRIGGER AS $$
DECLARE count NUMERIC;

BEGIN
    IF (NEW.type = 'FullTime') THEN
        SELECT COUNT(*) INTO count 
        FROM PartTime 
        WHERE NEW.uid = PartTime.uid;
        IF (count > 0) THEN 
            RETURN NULL;
        ELSE
            INSERT INTO FullTime VALUES (NEW.uid, DEFAULT);
            RAISE NOTICE 'Full time rider added';
            RETURN NEW;
        END IF;

    ELSIF (NEW.type = 'PartTime') THEN
        SELECT COUNT(*) INTO count 
        FROM FullTime 
        WHERE NEW.uid = FullTime.uid;

        IF (count > 0) THEN 
            RETURN NULL;
        ELSE
            INSERT INTO PartTime VALUES (NEW.uid, DEFAULT);
            RAISE NOTICE 'Part time rider added';
            RETURN NEW;
        END IF;
    ELSE RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER riders_trigger
AFTER INSERT ON DeliveryRiders /* return value of row-level trigger fired AFTER is always ignored */
FOR EACH ROW
EXECUTE PROCEDURE check_riders();


/*ISA check for users*/
CREATE OR REPLACE FUNCTION check_user()
RETURNS TRIGGER AS $$
DECLARE count NUMERIC;
BEGIN 
	IF (NEW.type = 'Customers') THEN
		SELECT COUNT(*) INTO count 
        FROM FDSManagers, RestaurantStaff, DeliveryRiders
        WHERE NEW.uid = FDSManagers.uid
        OR NEW.uid = RestaurantStaff.uid
        OR NEW.uid = DeliveryRiders.uid;
        
		IF (count > 0) THEN 
            RETURN NULL;
		ELSE
            INSERT INTO Customers VALUES (NEW.uid,DEFAULT,DEFAULT,NEW.cardDetails);
            RAISE NOTICE 'Customers added';
			RETURN NEW;

		END IF;
	ELSIF (NEW.type = 'FDSManagers') THEN
		SELECT COUNT(*) INTO count 
        FROM Customers, RestaurantStaff, DeliveryRiders
        WHERE NEW.uid = Customers.uid
        OR NEW.uid = RestaurantStaff.uid
        OR NEW.uid = DeliveryRiders.uid;

		IF (count > 0) THEN RETURN NULL;
		ELSE
			INSERT INTO FDSManagers VALUES (NEW.uid);
            RAISE NOTICE 'FDSManagers added';
			RETURN NEW;
		
		END IF;	
    ELSIF (NEW.type = 'RestaurantStaff') THEN
        SELECT COUNT(*) INTO count 
        FROM Customers, FDSManagers, DeliveryRiders
        WHERE NEW.uid = Customers.uid
        OR NEW.uid = FDSManagers.uid
        OR NEW.uid = DeliveryRiders.uid;

		IF (count > 0) THEN RETURN NULL;
		ELSE
			
				-- INSERT INTO RestaurantStaff VALUES (NEW.uid,NEW.restaurantID);
                RAISE NOTICE 'RestaurantStaff added';
				RETURN NEW;
			
		END IF;	
    ELSIF (NEW.type = 'DeliveryRiders') THEN
        SELECT COUNT(*) INTO count 
        FROM Customers, FDSManagers, RestaurantStaff
        WHERE NEW.uid = Customers.uid
        OR NEW.uid = FDSManagers.uid
        OR NEW.uid = RestaurantStaff.uid;

		IF (count > 0) THEN 
            RETURN NULL;
		ELSE
            -- INSERT INTO DeliveryRiders(uid,type) VALUES (NEW.uid, NEW.riderType);
            RAISE NOTICE 'DeliveryRiders added';
		    RETURN NEW;
		END IF;	
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_trigger
AFTER INSERT ON Users
FOR EACH ROW
EXECUTE PROCEDURE check_user();



/*Update reward point after order completion*/
CREATE OR REPLACE FUNCTION update_rewards()
RETURNS TRIGGER AS $$
DECLARE currStatus VARCHAR(50);
DECLARE customerId INTEGER;

BEGIN 
    currStatus := NEW.orderStatus;

    SELECT uid INTO customerId
    FROM Place
    WHERE NEW.orderid = Place.orderid;

    IF currStatus = 'Completed' THEN
        UPDATE Customers 
        SET rewardPts = rewardPts + TRUNC(NEW.cost)
        WHERE customerId = Customers.uid;
    END IF;
    RETURN NULL;


END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reward_trigger
AFTER UPDATE of orderStatus ON Orders
FOR EACH ROW
EXECUTE PROCEDURE update_rewards();


/*Update delivery rider number of complete orders after order completion*/
CREATE OR REPLACE FUNCTION update_bonus()
RETURNS TRIGGER AS $$
DECLARE currStatus VARCHAR(50);
DECLARE riderId uuid;
DECLARE riderType VARCHAR(255);
DECLARE dateO DATE;
DECLARE timeO TIME;

BEGIN
    currStatus := NEW.orderStatus;
	dateO := NEW.date;
	timeO := NEW.timeOrderPlace;

    SELECT uid INTO riderId
    FROM Delivers
    WHERE NEW.orderid = Delivers.orderid;

    SELECT type INTO riderType
    FROM DeliveryRiders
    WHERE riderId = DeliveryRiders.uid;

    IF (currStatus = 'Completed') THEN
        IF (riderType = 'FullTime') THEN
            UPDATE WorkingWeeks
            SET numCompleted = numCompleted + 1
            WHERE riderId = WorkingWeeks.uid
			AND dateO = WorkingWeeks.workDate;
        ELSIF (riderType = 'PartTime') THEN
            UPDATE WorkingDays 
            SET numCompleted = numCompleted + 1
            WHERE riderId = WorkingDays.uid
			AND dateO = WorkingDays.workDate
			AND timeO >= WorkingDays.intervalStart
			AND timeO <= WorkingDays.intervalEnd;
        END IF;
    END IF;
    RETURN NULL;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER bonus_trigger
AFTER UPDATE of orderStatus ON Orders
FOR EACH ROW
EXECUTE PROCEDURE update_bonus(); 


/*ISA check for Promotion*/
-- CREATE OR REPLACE FUNCTION check_promotion()
-- RETURNS TRIGGER AS $$
-- DECLARE count NUMERIC;

-- BEGIN
--     IF (NEW.type = 'FDSpromo') THEN
--         SELECT COUNT(*) INTO count 
--         FROM Restpromo 
--         WHERE NEW.promoID = Restpromo.promoID;
--         IF (count > 0) THEN 
--             RETURN NULL;
--         ELSE
--             INSERT INTO FDSpromo VALUES (NEW.promoID);
--             RAISE NOTICE 'FDSpromo added';
--             RETURN NEW;
--         END IF;

--     ELSIF (NEW.type = 'Restpromo') THEN
--         SELECT COUNT(*) INTO count 
--         FROM FDSpromo
--         WHERE NEW.promoID = FDSpromo.promoID;

--         IF (count > 0) THEN 
--             RETURN NULL;
--         ELSE
--             INSERT INTO Restpromo VALUES (NEW.promoID, NEW.restaurantID);
--             RAISE NOTICE 'Restpromo added';
--             RETURN NEW;
--         END IF;
--     ELSE RETURN NEW;
--     END IF;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER promo_trigger
-- AFTER INSERT ON Promotion
-- FOR EACH ROW
-- EXECUTE PROCEDURE check_promotion();


/*Check restaurant staff account creation*/
CREATE OR REPLACE FUNCTION check_reststaff()
RETURNS TRIGGER AS $$
DECLARE count NUMERIC;

BEGIN
    SELECT COUNT(*) INTO count 
    FROM RestaurantStaff
    WHERE RestaurantStaff.restaurantID = NEW.restaurantID;

    IF (count < 0) THEN
        RAISE NOTICE 'No Restaurant Staff Account Created'; 
        RETURN NULL; -- abort inserted row
    ELSE
        RAISE NOTICE 'Restaurant Staff available';
        RETURN NEW;
    END IF;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_rest_trigger
BEFORE INSERT ON Restaurants
FOR EACH ROW
EXECUTE PROCEDURE check_reststaff();

/*ensure one hour shift, check overlap*/
CREATE OR REPLACE FUNCTION check_shift()
RETURNS TRIGGER AS $$
DECLARE currShiftEnd NUMERIC;
DECLARE newShiftStart NUMERIC;

BEGIN
    IF EXISTS(
          SELECT 1 
          FROM workingDays W 
          WHERE (W.intervalStart <= NEW.intervalEnd 
          AND NEW.intervalStart <=  W.intervalEnd)
          AND NEW.uid = W.uid
          AND NOT (W.intervalStart = NEW.intervalStart OR NEW.intervalEnd = W.intervalEnd))
    THEN
        RAISE NOTICE 'Overlap shifts';
        RETURN NULL;
    ELSE 
        RAISE NOTICE 'One hour break between shifts';
        RETURN NEW;
    END IF;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_shift_trigger
BEFORE UPDATE OR INSERT ON WorkingDays
FOR EACH ROW
EXECUTE PROCEDURE check_shift();


/* Insert Data for Users*/
INSERT INTO Users (name, username, password, type) VALUES ('Alano', 'asunock0', 'SuKnMdGlSZv', 'Customers');
INSERT INTO Users (name, username, password, type) VALUES ('Ugo', 'uhumphery5', 'zzWtpV6x1W5','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('Theo', 'tadkina', 'mXQVb8fG','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('Jocelyn', 'jdodshund', '8XnPDwZN', 'Customers');
INSERT INTO Users (name, username, password, type) VALUES ('Paddie', 'ppaulline', 'Ake9PyGlLEh6', 'Customers');
INSERT INTO Users (name, username, password, type) VALUES ('qwerty', 'qwerty', '123qwe','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('queenie', 'queen', '123456','Customers'); --7

INSERT INTO Users (name, username, password, restaurantID, type) VALUES ('Ariela', 'arodolfi1', '6W8jV0Un', 1,'RestaurantStaff');
INSERT INTO Users (name, username, password, restaurantID, type) VALUES ('Kitti', 'kbelding6', 'CDvLeT', 2,'RestaurantStaff');
INSERT INTO Users (name, username, password, restaurantID, type) VALUES ('Antony', 'aclausenthue4', 'LS5CtMmb', 3,'RestaurantStaff'); --10

INSERT INTO Users (name, username, password, type) VALUES ('Taddeusz', 'tmanketell2', 'PjIpgl7J', 'FDSManagers');
INSERT INTO Users (name, username, password, type) VALUES ('Dodie', 'dfermerb', 'SLKtg2Q7kGn', 'FDSManagers');
INSERT INTO Users (name, username, password, type) VALUES ('Nyan', 'desmond', '123abc', 'FDSManagers');
INSERT INTO Users (name, username, password, type) VALUES ('Kesin', 'itskesin', '123abc', 'FDSManagers'); --14

INSERT INTO Users (name, username, password, riderType,type) VALUES ('Adrea', 'aveldens3', 'cdqUwd81YzX', 'FullTime','DeliveryRiders');
INSERT INTO Users (name, username, password, riderType,type) VALUES ('Adan', 'alaise7', 'blVy4LzR','FullTime','DeliveryRiders');
INSERT INTO Users (name, username, password, riderType,type) VALUES ('Elenore', 'epiatto8', 'jiWxXTs4Jjp','FullTime','DeliveryRiders');
INSERT INTO Users (name, username, password, riderType,type) VALUES ('Gary', 'gtarrier9', 'G92FSUJuvL9e','FullTime','DeliveryRiders');
INSERT INTO Users (name, username, password, riderType,type) VALUES ('Oona', 'oprevettc', 'xeLkYRLNSkJ','FullTime','DeliveryRiders'); --19

INSERT INTO Users (name, username, password, riderType, type) VALUES ('NyanCat', 'asdfgh', 'asdfghjkl','PartTime','DeliveryRiders');
INSERT INTO Users (name, username, password, riderType, type) VALUES ('Nadiah', 'wasd', 'zxcvbnm','PartTime','DeliveryRiders');
INSERT INTO Users (name, username, password, riderType, type) VALUES ('Jan', 'qwerty', 'qwertyuiop','PartTime','DeliveryRiders'); --22

INSERT INTO Users (name, username, password, type) VALUES ('ariel', 'ariel123', '123456','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('belle', 'belle123', '123456','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('jasmine', 'jas123', '123456','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('mulan', 'mulan123', '123456','Customers');
INSERT INTO Users (name, username, password, type) VALUES ('snow white', 'snow123', '123456','Customers'); --27



/*Insert Shifts for Full Time Schedule */
INSERT INTO ShiftOptions(shiftID, shiftDetail1, shiftDetail2) VALUES (1, '10am-2pm','3pm-7pm');
INSERT INTO ShiftOptions(shiftID, shiftDetail1, shiftDetail2) VALUES (2, '11am-3pm','4pm-8pm');
INSERT INTO ShiftOptions(shiftID, shiftDetail1, shiftDetail2) VALUES (3, '12pm-4pm','5pm-9pm');
INSERT INTO ShiftOptions(shiftID, shiftDetail1, shiftDetail2) VALUES (4, '1pm-5pm','6pm-10pm');

/*Insert Schedule for Riders */
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(20, '2020-01-08', '11:00', '15:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(20, '2020-01-08', '16:00', '20:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(20, '2020-03-20', '16:00', '20:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(20, '2020-04-20', '11:00', '15:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(20, '2020-04-20', '16:00', '20:00', 10);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(21, '2020-01-08', '11:00', '15:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(21, '2020-01-08', '16:00', '20:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(21, '2020-03-20', '16:00', '20:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(21, '2020-04-20', '11:00', '15:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(21, '2020-04-20', '16:00', '20:00', 10);

INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(22, '2020-01-08', '11:00', '15:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(22, '2020-01-08', '16:00', '20:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(22, '2020-03-20', '16:00', '20:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(22, '2020-04-20', '11:00', '15:00', 10);
INSERT INTO WorkingDays(uid, workDate, intervalStart, intervalEnd, numCompleted) VALUES(22, '2020-04-20', '16:00', '20:00', 10);

INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(15, '2020-01-08', 3, 13);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(16, '2020-01-09', 1, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(17, '2020-03-15', 1, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(18, '2020-04-20', 3, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(19, '2020-03-15', 1, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(15, '2020-04-20', 3, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(15, '2020-04-21', 3, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(15, '2020-04-22', 3, 15);
INSERT INTO WorkingWeeks(uid, workDate, shiftID, numCompleted) VALUES(15, '2020-04-10', 3, 15);

/* Insert Data for restaurants */
INSERT INTO Restaurants (name, location, minThreshold) VALUES ('Noma', '14 Texas Plaza', 5);
INSERT INTO Restaurants (name, location, minThreshold) VALUES ('Odette', '240 Vernon Hill', 5);
INSERT INTO Restaurants (name, location, minThreshold) VALUES ('Wolfgang Puck', '90 Mcguire Crossing', 3);
INSERT INTO Restaurants (name, location) VALUES ('Crystal Jade','123 Gowhere Road #01-27 Singapore 123456');
INSERT INTO Restaurants (name, location) VALUES ('What the fries','123 Gowhere Road #02-54 Singapore 123456');
INSERT INTO Restaurants (name, location) VALUES ('Zen food','456 Hungry Road #01-36 Singapore 456789');

/* Insert Data for categories */
INSERT INTO Categories(category) VALUES ('Malay Cuisine');
INSERT INTO Categories(category) VALUES ('Chinese Cuisine');
INSERT INTO Categories(category) VALUES ('Indian Cuisine');
INSERT INTO Categories(category) VALUES ('Japanese Cuisine');
INSERT INTO Categories(category) VALUES ('Korean Cuisine');
INSERT INTO Categories(category) VALUES ('Western Cuisine');

/* Insert Data for food */
/*Restaurant 1*/
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Nasi Briyani', 12.9, 1, 'Indian Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Tandoori Chicken', 22.8, 1, 'Indian Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Butter Chicken', 27.3, 1, 'Indian Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Tikka Masala', 27.8, 1, 'Indian Cuisine');

/*Restaurant 2*/
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Ayam Penyet', 5.0, 2, 'Malay Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Gado Gado', 13.0, 2, 'Malay Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Lontong', 6.3, 2, 'Malay Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Nasi Lemak', 9.2, 2, 'Malay Cuisine');

/*Restaurant 3*/
INSERT INTO Food (foodName, price, dailyLimit, RestaurantID, category) VALUES ('Tteokbokki', 14.9,100,3, 'Korean Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Kimchi Fried Rice', 10.5, 3, 'Korean Cuisine');

/*Restaurant 4*/
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Yang Zhou Fried Rice', 8, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Sweet and Sour Pork', 14, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Steam Egg', 5, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Hot and Sour Soup', 7, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Spring Rolls', 5, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Stir Fried Tofu', 5, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Chicken with Chestnuts', 15, 4, 'Chinese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Chicken Soup', 12, 4, 'Chinese Cuisine');

/*Restaurant 5*/
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Cheese Fries', 5, 5, 'Western Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Truffle Fries', 9, 5, 'Western Cuisine');

/*Restaurant 6*/
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Sushi', 29.9, 6, 'Japanese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Tempura', 19.7, 6, 'Japanese Cuisine');
INSERT INTO Food (foodName, price, RestaurantID, category) VALUES ('Char Siew Ramen', 8.5, 6, 'Japanese Cuisine');

/* Insert Data for Promo */
INSERT INTO Promotion (startDate,endDate,discAmt,type) VALUES ('2020-02-01','2020-02-28',5,'FDSpromo');
INSERT INTO Promotion (startDate,endDate,discPerc,type) VALUES ('2020-03-01','2020-05-30',0.2,'FDSpromo'); 
INSERT INTO Promotion (startDate,endDate,discAmt,type) VALUES ('2020-06-01','2020-06-30',5,'FDSpromo');
INSERT INTO Promotion (startDate,endDate,discPerc,restaurantID,type) VALUES ('2020-03-01','2020-05-30',0.2,1,'Restpromo');
INSERT INTO Promotion (startDate,endDate,discPerc,restaurantID,type) VALUES ('2020-06-01','2020-07-01',0.2,3,'Restpromo');
INSERT INTO Promotion (startDate,endDate,discPerc,restaurantID,type) VALUES ('2020-08-01','2020-09-01',0.15,4,'Restpromo');

INSERT INTO FDSpromo(promoID) VALUES(1);
INSERT INTO FDSpromo(promoID) VALUES(2);
INSERT INTO FDSpromo(promoID) VALUES(3);
INSERT INTO Restpromo(promoID, restID) VALUES(4,1);
INSERT INTO Restpromo(promoID, restID) VALUES(5,3);
INSERT INTO Restpromo(promoID, restID) VALUES(6,4);

/* Insert Data into Payment Option */
INSERT INTO PaymentOption(payOption) VALUES ('Cash');
INSERT INTO PaymentOption(payOption) VALUES ('Credit');


-- deliveryduration is in integer?
/* Insert Data into orders and fromMenu think of how to make it happen*/ 
/* Order 1: Confirmed */
INSERT INTO Orders(cost,location,date,deliveryDuration,payOption,area) VALUES (0,'81 Goodland Road','2020-04-20',0,'Cash','N'); /* let cost be initially deffered*/

INSERT INTO FromMenu(promoID,quantity,orderID,restaurantID,foodName) VALUES (5,5,1,3,'Tteokbokki');
INSERT INTO FromMenu(promoID,quantity,orderID,restaurantID,foodName) VALUES (5,3,1,3,'Kimchi Fried Rice');   

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star,promoid) VALUES (1,1,'no comments',5,5);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 1) WHERE orderID = 1; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM FromMenu M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 1 LIMIT 1)) WHERE orderID = 1; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 1 LIMIT 1) WHERE orderID = 1; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 1;
UPDATE Orders SET timeDepartToRest = '11:05:00' WHERE orderID = 1;
UPDATE Orders SET timeArriveRest = '11:11:00' WHERE orderID = 1;
UPDATE Orders SET timeDepartFromRest = '11:22:00' WHERE orderID = 1;
UPDATE Orders SET timeOrderDelivered = '11:45:00'  WHERE orderID = 1;

/*Order 2: Completed by .... */ 
INSERT INTO Orders(cost,location,date,deliveryDuration,payOption,area) VALUES (0,'346 Dennis Trail','2020-01-08',0,'Credit','S'); /* let cost be initially deffered*/
INSERT INTO FromMenu(promoID,quantity,orderID,restaurantID,foodName) VALUES (6,1,2,4,'Steam Egg');
INSERT INTO FromMenu(promoID,quantity,orderID,restaurantID,foodName) VALUES (6,1,2,4,'Sweet and Sour Pork');   
INSERT INTO FromMenu(promoID,quantity,orderID,restaurantID,foodName) VALUES (6,3,2,4,'Yang Zhou Fried Rice');
        
/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star) VALUES (3,2,'Nice food',4);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 2) WHERE orderID = 2; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM FromMenu M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 2 LIMIT 1)) WHERE orderID = 2; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 2 LIMIT 1) WHERE orderID = 2; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 2;
UPDATE Orders SET timeDepartToRest = '11:00:00' WHERE orderID = 2;
UPDATE Orders SET timeArriveRest = '11:15:00' WHERE orderID = 2;
UPDATE Orders SET timeDepartFromRest = '11:30:00' WHERE orderID = 2;
UPDATE Orders SET timeOrderDelivered = '11:45:00'  WHERE orderID = 2;

/* Order 3: Confirmed */
--partial order completion possible (quantity < availQty)
INSERT INTO Orders(location,payOption,area) VALUES ('333 Canberra Road','Cash','S'); 
INSERT INTO FromMenu(promoID,quantity,orderID,restaurantID,foodName) VALUES (5,4,3,3,'Tteokbokki');
INSERT INTO FromMenu(promoID,quantity,orderID,restaurantID,foodName) VALUES (5,3,3,3,'Kimchi Fried Rice');  

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star,promoid) VALUES (7,3,'Tastes great',5,5);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 3) WHERE orderID = 3; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM FromMenu M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 3 LIMIT 1)) WHERE orderID = 3; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 3 LIMIT 1) WHERE orderID = 3; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 3;
UPDATE Orders SET timeDepartToRest = '13:05:00' WHERE orderID = 3;
UPDATE Orders SET timeArriveRest = '13:11:00' WHERE orderID = 3;
UPDATE Orders SET timeDepartFromRest = '13:22:00' WHERE orderID = 3;
UPDATE Orders SET timeOrderDelivered = '13:45:00'  WHERE orderID = 3;

/* Order 4: Confirmed */
INSERT INTO Orders(location,payOption,area) VALUES ('311 Canberra Road','Cash','N'); 
INSERT INTO FromMenu(promoID,quantity,orderID,restaurantID,foodName) VALUES (5,4,4,3,'Tteokbokki');
INSERT INTO FromMenu(promoID,quantity,orderID,restaurantID,foodName) VALUES (5,4,4,3,'Kimchi Fried Rice');  

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star,promoid) VALUES (25,4,'Tastes great',5,5);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 4) WHERE orderID = 4; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM FromMenu M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 4 LIMIT 1)) WHERE orderID = 4; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 4 LIMIT 1) WHERE orderID = 4; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 4;
UPDATE Orders SET timeDepartToRest = '13:05:00' WHERE orderID = 4;
UPDATE Orders SET timeArriveRest = '13:11:00' WHERE orderID = 4;
UPDATE Orders SET timeDepartFromRest = '13:22:00' WHERE orderID = 4;
UPDATE Orders SET timeOrderDelivered = '13:45:00'  WHERE orderID = 4;

/* Order 5: Confirmed */
INSERT INTO Orders(location,payOption,area) VALUES ('911 Yishun Road','Credit','N'); 
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,5,6,'Sushi');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,5,6,'Tempura');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,5,6,'Char Siew Ramen');    

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star) VALUES (2,5,'Food slightly cold when arrived',1);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 5) WHERE orderID = 5; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM FromMenu M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 5 LIMIT 1)) WHERE orderID = 5; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 5 LIMIT 1) WHERE orderID = 5; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 5;
UPDATE Orders SET timeDepartToRest = '15:25:00' WHERE orderID = 5;
UPDATE Orders SET timeArriveRest = '15:31:00' WHERE orderID = 5;
UPDATE Orders SET timeDepartFromRest = '15:42:00' WHERE orderID = 5;
UPDATE Orders SET timeOrderDelivered = '15:55:00'  WHERE orderID = 5;


/* Order 6: Confirmed */
INSERT INTO Orders(location,payOption,area) VALUES ('987 Tampines Road','Cash','W'); 
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (2,6,6,'Sushi');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (2,6,6,'Tempura');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,6,6,'Char Siew Ramen');    

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star) VALUES (23,6,'Taste great',4);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 6) WHERE orderID = 6; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM FromMenu M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 6 LIMIT 1)) WHERE orderID = 6; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 6 LIMIT 1) WHERE orderID = 6; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 6;
UPDATE Orders SET timeDepartToRest = '15:25:00' WHERE orderID = 6;
UPDATE Orders SET timeArriveRest = '15:31:00' WHERE orderID = 6;
UPDATE Orders SET timeDepartFromRest = '15:42:00' WHERE orderID = 6;
UPDATE Orders SET timeOrderDelivered = '15:55:00'  WHERE orderID = 6;


/* Order 7: Confirmed */
INSERT INTO Orders(location,payOption,area) VALUES ('988 Tampines Road','Cash','W'); 
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (2,7,6,'Sushi');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (2,7,6,'Tempura');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,7,6,'Char Siew Ramen');    

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star) VALUES (26,7,'Taste great',4);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 7) WHERE orderID = 7; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM FromMenu M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 7 LIMIT 1)) WHERE orderID = 7; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 7 LIMIT 1) WHERE orderID = 7; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 7;
UPDATE Orders SET timeDepartToRest = '15:25:00' WHERE orderID = 7;
UPDATE Orders SET timeArriveRest = '15:31:00' WHERE orderID = 7;
UPDATE Orders SET timeDepartFromRest = '15:42:00' WHERE orderID = 7;
UPDATE Orders SET timeOrderDelivered = '15:55:00'  WHERE orderID = 7;


/* Order 8: Confirmed */
INSERT INTO Orders(location,payOption,area) VALUES ('988 Tampines Road','Credit','W'); 
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,8,6,'Sushi');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,8,6,'Tempura');
INSERT INTO FromMenu(quantity,orderID,restaurantID,foodName) VALUES (1,8,6,'Char Siew Ramen');    

/* Insert data into place */
INSERT INTO Place (uid,orderID,review,star) VALUES (1,8,'Great Sushi',4);

UPDATE Orders SET cost = (SELECT sum(M.quantity*F.price) FROM FromMenu M JOIN Food F USING (restaurantID,foodName) WHERE M.orderID = 8) WHERE orderID = 8; /*Food costs*/
UPDATE Orders SET cost = cost*(1-(SELECT COALESCE(P.discPerc,0) FROM FromMenu M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 8 LIMIT 1)) WHERE orderID = 8; /*For percentage promo*/
UPDATE Orders SET cost = cost-(SELECT COALESCE(P.discAmt,0) FROM Place M LEFT JOIN Promotion P USING (promoID) WHERE M.orderID = 8 LIMIT 1) WHERE orderID = 8; /*For amt promo*/

UPDATE Orders SET orderStatus = 'Completed' WHERE orderID = 8;
UPDATE Orders SET timeDepartToRest = '15:25:00' WHERE orderID = 8;
UPDATE Orders SET timeArriveRest = '15:31:00' WHERE orderID = 8;
UPDATE Orders SET timeDepartFromRest = '15:42:00' WHERE orderID = 8;
UPDATE Orders SET timeOrderDelivered = '15:58:00'  WHERE orderID = 8;


/* Insert Data into delivers */
INSERT INTO Delivers (orderID,uid,rating) VALUES (1,21,2);
INSERT INTO Delivers (orderID,uid,rating) VALUES (2,20,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (3,20,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (4,20,3);
INSERT INTO Delivers (orderID,uid,rating) VALUES (5,22,1);
INSERT INTO Delivers (orderID,uid,rating) VALUES (6,17,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (7,18,5);
INSERT INTO Delivers (orderID,uid,rating) VALUES (8,19,5);

/*Update WorkingDays SET intervalEnd = '22:00' WHERE uid = 18 AND workDate = '2020-01-08' AND intervalStart = '15:00'; 
UPDATE users SET cardDetails = '5200828282828210' WHERE uid = 4;*/

/* Create views */

/*PARTTIME. Consolidate shows for each parttime rider, how many weeks they actually worked in a month (If they
work one day in a week, it will be counted in totalWeeksWorked) and how many deliveries completed in a month */
CREATE VIEW ConsolidateP AS (
SELECT distinct P1.uid as pUid, 
P1.weeklyBasePay as pBasePay, 
EXTRACT(YEAR FROM WD1.workDate) as pYear, 
EXTRACT(Month FROM WD1.workDate) as pMonth,
count( distinct EXTRACT(WEEK FROM WD1.workDate)) as totalWeeksWorked, 
sum(WD1.numCompleted) as pComplete
FROM PartTime P1
INNER JOIN WorkingDays WD1 on P1.uid = WD1.uid
WHERE WD1.numCompleted > 0 /**Filter out weeks without any worked days at all for count(Extract(WEEK FROM WD.workDate))**/
GROUP BY P1.uid, EXTRACT(YEAR FROM WD1.workDate), EXTRACT(Month FROM WD1.workDate)
);

/*FULLTIME. ConsolidateF shows for each fulltime rider, how many months they actually worked (even if they worked one day in a month) 
and how many deliveries completed in a month */
CREATE VIEW ConsolidateF AS (
SELECT distinct F1.uid as fUid,
F1.monthlyBasePay as fBasePay,
EXTRACT(YEAR FROM WW1.workDate) as fYear,
EXTRACT(MONTH FROM WW1.workDate) as fMonth,
sum(WW1.numCompleted) as fCompleted
FROM FullTime F1
INNER JOIN WorkingWeeks WW1 on F1.uid = WW1.uid
WHERE WW1.numCompleted > 0  /**Filter out months without any worked days at all**/
GROUP BY F1.uid, EXTRACT(YEAR FROM WW1.workDate), EXTRACT(MONTH FROM WW1.workDate) 
);

CREATE VIEW workDetails AS(
SELECT DISTINCT p.uid as uid,
		EXTRACT(YEAR FROM WD.workDate) as year, 
        EXTRACT(Month FROM WD.workDate) as month, 
        sum(DATE_PART('hour', WD.intervalEnd - WD.intervalStart)) as totalHours,
		sum(WD.numCompleted) as numCompleted
FROM PartTime P INNER JOIN WorkingDays WD USING (uid) 
WHERE WD.numCompleted > 0 
GROUP BY P.uid, EXTRACT(YEAR FROM WD.workDate), EXTRACT(Month FROM WD.workDate)
UNION
SELECT distinct F.uid as uid,
		EXTRACT(YEAR FROM WW.workDate) as year, 
		EXTRACT(Month FROM WW.workDate) as month, 
		count(shiftID) * 8 as totalHours,
		sum(WW.numCompleted) as numCompleted
FROM FullTime F INNER JOIN WorkingWeeks WW USING (uid) 
WHERE WW.numCompleted > 0 
GROUP BY F.uid, EXTRACT(YEAR FROM WW.workDate), EXTRACT(Month FROM WW.workDate)
);

CREATE VIEW driverSalary AS (
SELECT CP.puid as uid,
	   CP.pYear as year, 
       CP.pMonth as month, 
       CP.pComplete * DR.baseDeliveryFee + CP.totalWeeksWorked * CP.pBasePay as monthSalary 
FROM ConsolidateP CP RIGHT JOIN DeliveryRiders DR on DR.uid = CP.pUid 
UNION
SELECT CF.fuid as uid,
       CF.fYear as year, 
       CF.fMonth as month, 
       CF.fCompleted * DR.baseDeliveryFee + CF.fBasePay as monthSalary 
FROM DeliveryRiders DR LEFT JOIN ConsolidateF CF on DR.uid = CF.fUid 
);
            