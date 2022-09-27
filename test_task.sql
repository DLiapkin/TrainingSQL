CREATE DATABASE sql_test;

GO

USE sql_test;

CREATE TABLE bank (
	id INT CHECK (id > 0) NOT NULL PRIMARY KEY identity,
	name VARCHAR(255) NOT NULL
	);

CREATE TABLE city (
	id INT CHECK (id > 0) NOT NULL PRIMARY KEY identity,
	name VARCHAR(255) NOT NULL
	);

CREATE TABLE filial (
	id INT CHECK (id > 0) NOT NULL PRIMARY KEY identity,
	cityId INT CHECK (cityId > 0) DEFAULT NULL,
	adress VARCHAR(255) NOT NULL,
	bankId INT CHECK (bankId > 0) DEFAULT NULL,
	FOREIGN KEY (bankId) REFERENCES bank(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (cityId) REFERENCES city(id) ON UPDATE CASCADE ON DELETE CASCADE
	);

CREATE TABLE socialStatus (
	id INT CHECK (id > 0) NOT NULL PRIMARY KEY identity,
	name VARCHAR(255) NOT NULL DEFAULT ''
	);

CREATE TABLE client (
	id INT CHECK (id > 0) NOT NULL PRIMARY KEY identity,
	name VARCHAR(255) NOT NULL,
	socialStatusId INT CHECK (socialStatusId > 0) NOT NULL,
	FOREIGN KEY (socialStatusId) REFERENCES socialStatus (id) ON UPDATE CASCADE ON DELETE CASCADE
	);

CREATE TABLE account (
	id INT CHECK (id > 0) NOT NULL PRIMARY KEY identity,
	bankId INT CHECK (bankId > 0) NOT NULL,
	clientId INT CHECK (clientId > 0) NOT NULL,
	amount INT DEFAULT 0,
	FOREIGN KEY (bankId) REFERENCES bank(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (clientId) REFERENCES client(id) ON UPDATE CASCADE ON DELETE CASCADE,
	UNIQUE(bankId, clientId)
	);

CREATE TABLE card (
	id INT CHECK (id > 0) NOT NULL PRIMARY KEY identity,
	accountId INT CHECK (accountId > 0) NOT NULL,
	amount INT DEFAULT 0,
	FOREIGN KEY (accountId) REFERENCES account(id) ON UPDATE CASCADE ON DELETE CASCADE
	);

INSERT INTO bank (name)
VALUES ('Belarusbank'),
	('VTB'),
	('Belinvest'),
	('BNB'),
	('Belagroprombank');

INSERT INTO city (name)
VALUES ('Minsk'),
	('Gomel'),
	('Grodno'),
	('Mogilev'),
	('Brest');

INSERT INTO filial (cityId,adress,bankId)
VALUES (1,'Yakuba Kolasa 12',1),
	(2,'Dimitrava 20',1),
	(2,'Frunze 3',2),
	(2,'Lenina 45',2),
	(3,'Sovetskih Pogranichnikov 92',3),
	(1,'Pobedi 12',4),
	(4,'Mira 55',5);

INSERT INTO socialStatus (name)
VALUES ('veteran'),
	('disabled'),
	('retiree'),
	('unemployed'),
	('base');

INSERT INTO client (name,socialStatusId)
VALUES ('Petr',1),
	('Ivan',2),
	('Dmitry',5),
	('Vasya',4),
	('Maxim',3);

INSERT INTO account (bankId,clientId,amount)
VALUES (1,1,1000),
	(2,2,1000),
	(3,3,1000),
	(4,4,500),
	(5,5,500);

INSERT INTO card (accountId,amount)
VALUES (1,100),
	(1,100),
	(2,100),
	(2,200),
	(3,50),
	(3,150),
	(4,25),
	(4,75),
	(5,155),
	(5,145);

GO

-- TASKS
-- 1st task
SELECT DISTINCT bank.name
FROM bank
	JOIN filial ON bank.id = filial.bankId
	JOIN city ON filial.cityId = city.id
WHERE city.name = 'Gomel';

-- 2nd task
SELECT card.amount, client.name, bank.name
FROM bank
	JOIN account ON bank.id = account.bankId
	JOIN client ON account.clientId = client.id
	JOIN card ON account.id = card.accountid;

-- 3rd task
SELECT accountId, sum(card.amount) AS summ, account.amount - sum(card.amount) AS difference
FROM card
	LEFT JOIN account ON account.id = card.accountId
GROUP BY accountId, account.amount
ORDER BY accountId;

-- 4.1 task (group by)
SELECT socialStatus.name, count(card.id)
FROM socialStatus
	LEFT JOIN client ON client.socialStatusId = socialStatus.id
	LEFT JOIN account ON client.id = account.clientId
	LEFT JOIN card ON card.accountId = account.Id
GROUP BY socialStatus.name;

-- 4.2 task
SELECT status.name,(
		SELECT COUNT(*)
		FROM socialStatus AS status2
			LEFT JOIN client ON client.socialStatusId = status2.id
			LEFT JOIN account ON client.id = account.clientId
			LEFT JOIN card ON card.accountId = account.Id
		WHERE status2.name = status.name
		) AS cards
FROM socialStatus AS status;

-- 5 task
GO

CREATE PROCEDURE usp_Status_Add_Money (@status_id INT)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @result INT;

	SELECT @result = count(*)
	FROM account
		JOIN client ON client.id = account.clientId
		JOIN socialStatus ON socialStatus.id = client.socialStatusId
	WHERE client.socialStatusId = @status_id;

	IF @result = 0
	BEGIN
		RAISERROR ('There is no such status or people with it!',16,1);
	END

	UPDATE account
		SET account.amount = account.amount + 10
		FROM account
			JOIN client ON client.id = account.clientId
			JOIN socialStatus ON socialStatus.id = client.socialStatusId
		WHERE socialStatus.id = @status_id;
END

GO

SELECT *
FROM account;

EXECUTE usp_Status_Add_Money 2;

SELECT *
FROM account;

-- 6 task
SELECT a.id, (
		SELECT a2.amount - sum(card.amount)
		FROM account as a2
			JOIN card ON a2.id = card.accountId
		WHERE a.id = a2.id
		GROUP BY a2.amount
		) AS result
FROM account AS a;

-- task 7
GO

CREATE PROCEDURE usp_Card_Transfer_Money (@amount INT, @cardId INT)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @free_money INT;

	BEGIN TRY
		BEGIN TRANSACTION

		SELECT @free_money = account.amount - sum(card.amount)
		FROM account
			JOIN card ON card.accountId = account.id
		WHERE account.id = (
				SELECT account.id
				FROM account
					JOIN card ON account.id = card.accountId
				WHERE card.id = @cardId
				)
		GROUP BY account.id, account.amount;

		IF @amount > @free_money
		BEGIN
			RAISERROR ('Insufficent amount on account',16,1);
		END

		UPDATE card
			SET card.amount = card.amount + @amount
			WHERE card.id = @cardId;
   END TRY
   BEGIN CATCH
      ROLLBACK TRANSACTION
	  RETURN
   END CATCH

   COMMIT TRANSACTION;
END

GO

SELECT *
FROM card;

EXEC usp_Card_Transfer_Money 99, 9;

SELECT *
FROM card;

-- 8 task
GO

CREATE TRIGGER TR_Amount_Update ON account
FOR UPDATE
AS
BEGIN
	DECLARE @current_cards INT;
	DECLARE @cards_money INT;
	DECLARE @new_amount  INT;

	SELECT @new_amount = amount 
	FROM inserted;

	SELECT @current_cards = count(card.id)
	FROM account
		JOIN card ON card.accountId = account.id
	WHERE account.id = (
		SELECT id 
		FROM inserted
		)
	GROUP BY account.id;

	SELECT @cards_money = sum(card.amount)
	FROM account
		JOIN card ON card.accountId = account.id
	WHERE account.id = (
		SELECT id 
		FROM inserted
		)
	GROUP BY account.id;

	IF @current_cards > 0
	BEGIN
		IF @new_amount < @cards_money
		BEGIN
			PRINT 'The new value is less than the amount on existing cards'
			ROLLBACK TRANSACTION;
		END
	END
END

GO

SELECT *
FROM account;

UPDATE account
SET account.amount = 900
WHERE account.id = 1;

SELECT *
FROM account;