--adaugam tabelele pt care se vor rula testele
INSERT INTO Tables(Name) VALUES('Categorii')
INSERT INTO Tables(Name) VALUES('Masini')
INSERT INTO Tables(Name) VALUES('Masini_Categorii')

--adaugam testele pt insert-uri pe tabele
INSERT INTO Tests(Name) VALUES('delete_masini_categorii')
INSERT INTO Tests(Name) VALUES('delete_masini')
INSERT INTO Tests(Name) VALUES('delete_categorii')

--adaugam testele pt delete-uri pe tabele
INSERT INTO Tests(Name) VALUES('delete_masini_categorii')
INSERT INTO Tests(Name) VALUES('delete_masini')
INSERT INTO Tests(Name) VALUES('delete_categorii')

--adaugam in TestTables combinatiile ce descriu ce test va rula pe fiecare tabel si in ce ordine

--pt insert-uri
INSERT INTO TestTables(TestID, TableID, NoOfRows, Position) VALUES(1, 1, 1000, 1)
INSERT INTO TestTables(TestID, TableID, NoOfRows, Position) VALUES(2, 2, 1000, 2)
INSERT INTO TestTables(TestID, TableID, NoOfRows, Position) VALUES(3, 3, 1000, 3)

--pt delete-uri
INSERT INTO TestTables(TestID, TableID, NoOfRows, Position) VALUES(4, 3, 1000, 4)
INSERT INTO TestTables(TestID, TableID, NoOfRows, Position) VALUES(5, 2, 1000, 5)
INSERT INTO TestTables(TestID, TableID, NoOfRows, Position) VALUES(6, 1, 1000, 6)

--cream procedurile ce vor realiza insert-urile (delete-urile nu necesita proceduri)

CREATE PROCEDURE insert_categorii
AS
BEGIN
	DECLARE @NumberOfRows INT
	DECLARE @n INT

	DECLARE @denumireCategorie VARCHAR(50)

	SELECT TOP 1 @NumberOfRows = NoOfRows FROM TestTables WHERE TableID = 1

	SET @n=1
	WHILE @n <= @NumberOfRows
	BEGIN
		SET @denumireCategorie = 'Categorie' + CONVERT (VARCHAR(5), @n) --Categorie1, Categorie2, ...
		INSERT INTO Categorii(denumire) VALUES(@denumireCategorie)
		SET @n=@n+1
	END
END

CREATE PROCEDURE insert_masini
AS
BEGIN
	DECLARE @NumberOfRows INT
	DECLARE @n INT

	DECLARE @marca VARCHAR(50)
	DECLARE @model VARCHAR(50)
	DECLARE @an INT
	DECLARE @culoare VARCHAR(50)
	DECLARE @fk_IdCond INT

	DECLARE @stare_motor VARCHAR(50)
	DECLARE @stare_exterior VARCHAR(50)
	DECLARE @stare_interior VARCHAR(50)

	SELECT TOP 1 @NumberOfRows = NoOfRows FROM TestTables WHERE TableID = 2

	SET @n=1
	WHILE @n <= @NumberOfRows
	BEGIN
		SET @marca = 'Marca' + CONVERT (VARCHAR(5), @n)
		SET @model = 'Model' + CONVERT (VARCHAR(5), @n)
		SET @an = @n
		SET @culoare = 'Culoare' + CONVERT (VARCHAR(5), @n)

		--trebuie generata si o conditie pt fiecare masina deoarece este nevoie pt foreign key-ul id_cond
		SET @stare_motor = 'Stare_Motor' + CONVERT (VARCHAR(5), @n)
		SET @stare_exterior = 'Stare_Exterior' + CONVERT (VARCHAR(5), @n)
		SET @stare_interior = 'Stare_Interior' + CONVERT (VARCHAR(5), @n)

		INSERT INTO Conditii(stare_motor, stare_exterior, stare_interior)
		VALUES(@stare_motor, @stare_exterior, @stare_interior)

		--@@IDENTITY este primary key-ul ultimei entitati adaugate, in cazul nostru fiind id_cond
		INSERT INTO Masini(marca, model, an, culoare, id_cond)
		VALUES(@marca, @model, @an, @culoare, @@IDENTITY)

		SET @n=@n+1
	END
END

CREATE PROCEDURE insert_masini_categorii
AS
BEGIN
	DECLARE @NumberOfRows INT
	DECLARE @n INT

	DECLARE @fk_IdCat INT
	DECLARE @fk_CodM INT

	SELECT TOP 1 @NumberOfRows = NoOfRows FROM TestTables WHERE TableID = 3

	SELECT @fk_IdCat = Min(id_cat) FROM Categorii

	--iteram cu un cursor peste id-urile cod_m ale masinilor
	DECLARE cursorCoduriM CURSOR FAST_FORWARD FOR SELECT cod_m FROM Masini;
	OPEN cursorCoduriM;

	FETCH NEXT FROM cursorCoduriM INTO @fk_CodM
	SET @n=1

	--vom avea perechi de forma (1, 1), (1, 2), (1, 3), ...
	WHILE @n <= @NumberOfRows AND @@FETCH_STATUS=0
	BEGIN
		INSERT INTO Masini_Categorii(id_cat, cod_m) VALUES(@fk_IdCat, @fk_CodM)
		FETCH NEXT FROM cursorCoduriM INTO @fk_CodM
		SET @n=@n+1
	END
END

--cream view-urile pe care le vom testa

--se afiseaza toate campurile tuturor masinilor
CREATE VIEW view_masini AS
SELECT marca, model, an, culoare FROM Masini

--se afiseaza marca, modelul si starea motorului pt toate masinile
CREATE VIEW view_conditii_motor_masini AS
SELECT M.marca, M.model, C.stare_motor AS motor
FROM Masini M INNER JOIN Conditii C ON M.id_cond=C.id_cond

--se afiseaza denumirea si numarul de masini pt fiecare categorie, chiar si cele cu 0 masini
CREATE VIEW view_numar_masini_per_categorie AS
SELECT C.denumire, COUNT(M.cod_m) numar_masini FROM 
(
(Masini M INNER JOIN Masini_Categorii MC ON M.cod_m=MC.cod_m)
RIGHT JOIN Categorii C ON MC.id_cat=C.id_cat
)
GROUP BY C.denumire

--adaugam view-urile in tabelul Views
INSERT INTO Views(Name) VALUES('view_masini')
INSERT INTO Views(Name) VALUES('view_conditii_motor_masini')
INSERT INTO Views(Name) VALUES('view_numar_masini_per_categorie')

--adaugam testele pt views in tabelul Tests
INSERT INTO Tests(Name) VALUES('test_view_masini')
INSERT INTO Tests(Name) VALUES('test_view_conditii_motor_masini')
INSERT INTO Tests(Name) VALUES('test_view_numar_masini_per_categorie')

--adaugam in TestViews combinatiile ce descriu ce test va rula pentru fiecare view
INSERT INTO TestViews(TestID, ViewID) VALUES(10, 1)
INSERT INTO TestViews(TestID, ViewID) VALUES(11, 2)
INSERT INTO TestViews(TestID, ViewID) VALUES(12, 3)

--rulam toate testele, masurand timpii pt toate testele,
--dupa care doar pt adaugare in fiecare tabel, dupa pt fiecare view
CREATE PROCEDURE TestRun1 @testRunID INT
AS
BEGIN
	DECLARE @dStart DATETIME
	DECLARE @dEnd DATETIME

	DECLARE @d1 DATETIME
	DECLARE @d2 DATETIME
	DECLARE @d3 DATETIME
	DECLARE @d4 DATETIME
	DECLARE @d5 DATETIME

	--stergem tot ca sa fim siguri ca nu avem date, in ordinea corespunzatoare
	DELETE FROM Masini_Categorii
	DELETE FROM Masini
	DELETE FROM Categorii

	SET @dStart = GETDATE()

			EXEC insert_categorii
		SET @d1 = GETDATE()
			EXEC insert_masini
		SET @d2 = GETDATE()
			EXEC insert_masini_categorii
		SET @d3 = GETDATE()
		
			SELECT * FROM view_masini
		SET @d4 = GETDATE()
			SELECT * FROM view_conditii_motor_masini
		SET @d5 = GETDATE()
			SELECT * FROM view_numar_masini_per_categorie

	SET @dEnd = GETDATE()

	UPDATE TestRuns SET StartAt = @dStart, EndAt = @dEnd WHERE TestRunID = @testRunID

	INSERT INTO TestRunTables VALUES (@testRunID, 1, @dStart, @d1)
	INSERT INTO TestRunTables VALUES (@testRunID, 2, @d1, @d2)
	INSERT INTO TestRunTables VALUES (@testRunID, 3, @d2, @d3)

	INSERT INTO TestRunViews VALUES (@testRunID, 1, @d3, @d4)
	INSERT INTO TestRunViews VALUES (@testRunID, 2, @d4, @d5)
	INSERT INTO TestRunViews VALUES (@testRunID, 3, @d5, @dEnd)
END

--initializarea primului test run
INSERT INTO TestRuns
VALUES ('Test run care masoara timpul consumat dupa adaugarea a 1000 de entitati in toate 3 tabelele si testarea celor 3 view-rui, dar masoara si timpii intre fiecare test individual',
null, null)

--@@IDENTITY va retine id-ul testRun-ului adaugat ultima data
EXEC TestRun1 @@IDENTITY
