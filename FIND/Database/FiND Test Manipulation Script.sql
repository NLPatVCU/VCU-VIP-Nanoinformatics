# Select "FiND" as default database before executing script!

INSERT INTO publications(PublicationID, PublicationTitle, PublicationYear) 
     VALUES('20113659', 'Monkeys In The Wind', '2001-12-07');
INSERT INTO authors(AuthorID, AuthorsLastName, AuthorsFirstName, AuthorsMiddleInit, AffiliationName) 
     VALUES('0', 'Franklin', 'Benjamin', 'R', 'US President - White House');
INSERT INTO authors(AuthorID, AuthorsLastName, AuthorsFirstName, AuthorsMiddleInit, AffiliationName) 
     VALUES('1', 'Franklin', 'Ben', 'A', 'Janitor');


SELECT AuthorID FROM authors WHERE (AuthorsLastName, AuthorsFirstName) = ('Franklin', 'Benjamin');

# publicationauthors Insert must have same AuthorID as associated "authors" table to succeed.
# INSERT into authors table first, then publication authors.
INSERT INTO publicationauthors(PublicationID, AuthorID) 
     VALUES('20113659', '1');

# Delete Stuff From Database    
DELETE FROM publicationauthors WHERE PublicationID = '20113659';
DELETE FROM publications WHERE PublicationID = '20113659'; 
DELETE FROM authors WHERE AuthorID = '1';