CREATE FUNCTION string_vid(@string VARCHAR(50))
RETURNS INT AS
BEGIN
	--daca este vid sau null sau contine doar whitespaces
	IF(@string LIKE '% %' OR @string LIKE '%	%' OR @string='' OR @string IS NULL)
		RETURN 1;

	RETURN 0;
END;



CREATE PROCEDURE adauga_categorie @denumire VARCHAR(50)
AS
BEGIN
	IF(dbo.string_vid(@denumire)=1)
		RAISERROR('denumirea nu poate contine spatii sau sa fie vida', 16, 1);
	ELSE
		INSERT INTO Categorii(denumire) VALUES(@denumire);
END



CREATE PROCEDURE sterge_categorie @id_cat INT
AS
BEGIN
	--daca niciuna dintre categorii nu are acest id
	IF NOT EXISTS (SELECT * FROM Categorii WHERE id_cat=@id_cat)
		RAISERROR('niciuna dintre categorii nu are acest id', 16, 1);
	ELSE
		DELETE FROM Categorii WHERE id_cat=@id_cat;
END



CREATE PROCEDURE update_categorie @id_cat INT, @denumire VARCHAR(50)
AS
BEGIN
	--daca niciuna dintre categorii nu are acest id
	IF NOT EXISTS (SELECT * FROM Categorii WHERE id_cat=@id_cat)
		RAISERROR('niciuna dintre categorii nu are acest id', 16, 1);
	ELSE
	BEGIN
		IF(dbo.string_vid(@denumire)=1)
			RAISERROR('denumirea nu poate contine spatii sau sa fie vida', 16, 1);
		ELSE
			UPDATE Categorii SET denumire=@denumire WHERE id_cat=@id_cat;
	END
END



CREATE PROCEDURE find_categorie @id_cat INT
AS
BEGIN
	SELECT * FROM Categorii WHERE id_cat=@id_cat
	
	IF(@@ROWCOUNT=0)
		RAISERROR('niciuna dintre categorii nu are acest id', 16, 1);
END



CREATE PROCEDURE adauga_masina @marca VARCHAR(50), @model VARCHAR(50), @an INT, @culoare VARCHAR(50), @id_cond INT
AS
BEGIN
	IF(dbo.string_vid(@marca)=1 OR dbo.string_vid(@model)=1 OR dbo.string_vid(@culoare)=1)
		RAISERROR('marca, modelul sau culoarea nu pot contine spatii sau sa fie vide', 16, 1);
	ELSE
	BEGIN
		IF(@id_cond IS NULL)
			INSERT INTO Masini(marca, model, an, culoare) VALUES(@marca, @model, @an, @culoare);
		ELSE
			INSERT INTO Masini(marca, model, an, culoare, id_cond) VALUES(@marca, @model, @an, @culoare, @id_cond);
	END
END



CREATE PROCEDURE sterge_masina @cod_m INT
AS
BEGIN
	--daca niciuna dintre categorii nu are acest id
	IF NOT EXISTS (SELECT * FROM Masini WHERE cod_m=@cod_m)
		RAISERROR('niciuna dintre masini nu are acest id', 16, 1);
	ELSE
		DELETE FROM Masini WHERE cod_m=@cod_m;
END



CREATE PROCEDURE update_masina @cod_m INT, @marca VARCHAR(50), @model VARCHAR(50), @an INT, @culoare VARCHAR(50), @id_cond INT
AS
BEGIN
	--daca niciuna dintre categorii nu are acest id
	IF NOT EXISTS (SELECT * FROM Masini WHERE cod_m=@cod_m)
		RAISERROR('niciuna dintre masini nu are acest id', 16, 1);
	ELSE
	BEGIN
		--daca un parametru este null inseamna ca acesta nu se doreste a fi actualizat

		--daca una dintre campurile string contine doar spatii sau este vid:
		IF(
			dbo.string_vid(@marca)=1 AND @marca IS NOT NULL
			OR dbo.string_vid(@model)=1 AND @model IS NOT NULL
			OR dbo.string_vid(@culoare)=1 AND @culoare IS NOT NULL
		)
			RAISERROR('marca, modelul sau culoarea nu pot contine spatii sau sa fie vide', 16, 1);
		ELSE
		BEGIN
			IF(@marca IS NOT NULL)
				UPDATE Masini SET marca=@marca WHERE cod_m=@cod_m;
			
			IF(@model IS NOT NULL)
				UPDATE Masini SET model=@model WHERE cod_m=@cod_m;

			IF(@an IS NOT NULL)
				UPDATE Masini SET an=@an WHERE cod_m=@cod_m;

			IF(@culoare IS NOT NULL)
				UPDATE Masini SET culoare=@culoare WHERE cod_m=@cod_m;

			IF(@id_cond IS NOT NULL)
				UPDATE Masini SET id_cond=@id_cond WHERE cod_m=@cod_m;
		END
	END
END



CREATE PROCEDURE find_masina @cod_m INT
AS
BEGIN
	SELECT * FROM Masini WHERE cod_m=@cod_m
	
	IF(@@ROWCOUNT=0)
		RAISERROR('niciuna dintre masini nu are acest id', 16, 1);
END



CREATE PROCEDURE adauga_masini_categorii @cod_m INT, @id_cat INT
AS
BEGIN
	INSERT INTO Masini_Categorii(cod_m, id_cat) VALUES(@cod_m, @id_cat)
END



CREATE PROCEDURE sterge_masini_categorii @cod_m INT, @id_cat INT
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM Masini_Categorii WHERE cod_m=@cod_m AND id_cat=@id_cat)
		RAISERROR('nu exista aceasta combinatie de id-uri', 16, 1);
	ELSE
		DELETE FROM Masini_Categorii WHERE cod_m=@cod_m AND id_cat=@id_cat;
END



CREATE PROCEDURE modifica_masini_categorii @cod_m INT, @id_cat INT, @new_cod_m INT, @new_id_cat INT
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM Masini_Categorii WHERE cod_m=@cod_m AND id_cat=@id_cat)
		RAISERROR('nu exista aceasta combinatie de id-uri', 16, 1);
	ELSE
	BEGIN
		IF(@new_cod_m IS NOT NULL)
			UPDATE Masini_Categorii SET cod_m=@new_cod_m WHERE cod_m=@cod_m AND id_cat=@id_cat;

		IF(@new_id_cat IS NOT NULL)
			UPDATE Masini_Categorii SET id_cat=@new_id_cat WHERE cod_m=@cod_m AND id_cat=@id_cat;
	END
END



CREATE PROCEDURE find_masini_categorii @cod_m INT, @id_cat INT
AS
BEGIN
	SELECT * FROM Masini_Categorii WHERE cod_m=@cod_m AND id_cat=@id_cat
	
	IF(@@ROWCOUNT=0)
		RAISERROR('nu exista aceasta combinatie de id-uri', 16, 1);
END



--categoriile
CREATE VIEW view_categorii AS
SELECT denumire FROM Categorii

--numarul de masini pt fiecare culoare existenta
CREATE VIEW view_numar_culori_masini AS
SELECT M.culoare, COUNT(M.cod_m) numar_masini FROM Masini M
GROUP BY M.culoare



--index nonclustered pentru categorii, dupa denumire, alfabetic
CREATE INDEX IX_categorii_denumire_asc ON Categorii(denumire ASC)


--index nonclustered pentru masini, dupa culoare, alfabetic
CREATE INDEX IX_masini_culoare_asc ON Masini(culoare ASC)



SELECT * FROM view_numar_culori_masini
SELECT * FROM view_categorii

--DELETE FROM Masini
--DELETE FROM Categorii
--DELETE FROM Masini_Categorii
--DELETE FROM Masini

--SELECT * FROM Masini
--SELECT * FROM Categorii
--SELECT * FROM Conditii
--SELECT * FROM Masini_Categorii
--SELECT * FROM Conditii

