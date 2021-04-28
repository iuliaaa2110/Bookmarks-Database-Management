--Creare tabele
----SELECT 'DROP TABLE "' || TABLE_NAME || '" CASCADE CONSTRAINTS;' FROM user_tables;
--DROP TABLE "USERS" CASCADE CONSTRAINTS;
--DROP TABLE "POSTS" CASCADE CONSTRAINTS;
--DROP TABLE "CATEGORIES" CASCADE CONSTRAINTS;
--DROP TABLE "TAGS" CASCADE CONSTRAINTS;
--DROP TABLE "BOOKMARKED_POSTS" CASCADE CONSTRAINTS;
--DROP TABLE "POST_TAG" CASCADE CONSTRAINTS;
--DROP TABLE "COMMENTS" CASCADE CONSTRAINTS;

create table Users(
    Id number(5) primary key,
    
    username varchar(30) not null,
    password varchar(2000) not null,
    last_name varchar(30) not null,
    first_name varchar(30) not null,
    Role varchar(15) default 'User'
);

alter table Users
add constraint users unique (username);

create table Posts(
    Id number(5) primary key,
    user_id not null,
    constraint FK_Post_User foreign key (User_Id) references Users(Id),
    
    Title varchar(50) not null,
    Content varchar(2000) not null,
    Description varchar(250),
    Rating number(5) default 0,
    n_com number(5) default 0
);

create table Categories(
    Id number(5) primary key,
    Name varchar(50) not null,
    
    constraint unique_category unique (name)
);


create table Tags(
    Id number(5) primary key,
    category_id not null,
    constraint FK_TAG_CATEGORY foreign key (Category_Id) references Categories(Id),
    
    Content varchar(30) not null,
    constraint unique_category_ unique (content)
);


create table Bookmarked_Posts(
    user_id not null,
    post_id not null,
    constraint FK_BOOKMARKED_POSTS_USER foreign key (User_Id) references Users(Id),
    constraint FK_BOOKMARKED_POSTS_POST foreign key (Post_Id) references Posts(Id),
    PRIMARY KEY(User_Id, Post_Id)
);


create table Post_Tag(
    post_id not null,
    tag_id not null,
    constraint FK_POST_TAG_POST foreign key (Post_Id) references Posts(Id),
    constraint FK_POST_TAG_TAG foreign key (Tag_Id) references Tags(Id),
    PRIMARY KEY(Post_Id, Tag_Id)
);


create table Comments(
    Id number(5) primary key,
    user_id not null,
    post_id not null,
    
    constraint FK_COMMENT_USER foreign key (User_Id) references Users(Id),
    constraint FK_COMMENT_POST foreign key (Post_Id) references Posts(Id),
    
    
    Content varchar(100) not null
);


--Triggeri:

create or replace TRIGGER generate_id_users
    BEFORE INSERT on users
    FOR EACH ROW 
        declare n number(5):=1000;
        b number(2);
        begin
            
            dbms_output.put_line('TRIGGER generate_id_users');
            
            select count(1) into b
            from users;
            
            if b > 0 then
                select max(id) into n
                from users;
            end if;

            :new.id := n + 1;
            
        end ;
        /
        

CREATE OR REPLACE TRIGGER EncryptingPassword
    BEFORE INSERT
    on Users
    FOR EACH ROW 
        declare
            l_user_id users.ID%TYPE := :new.id;
            l_user_psw   VARCHAR2 (2000) := :new.password;
           
            l_key        VARCHAR2 (200) := '1234567890999999';
            l_mod NUMBER
                 :=   DBMS_CRYPTO.ENCRYPT_AES128
                    + DBMS_CRYPTO.CHAIN_CBC
                    + DBMS_CRYPTO.PAD_PKCS5;
           l_enc    varchar(2000);
        BEGIN
         dbms_output.put_line(chr(10)  || 'TRIGGER generate_id_users');
         DBMS_OUTPUT.put_line (:new.password);
           l_enc :=
              to_char(DBMS_CRYPTO.encrypt (UTL_I18N.string_to_raw (l_user_psw, 'AL32UTF8'),
                                   l_mod,
                                   UTL_I18N.string_to_raw (l_key, 'AL32UTF8')));
    
              DBMS_OUTPUT.put_line ('Encrypted=' || l_enc);
    
            :new.password := l_enc;
        end;
/

create or replace TRIGGER Posts_Trigger --generez id-ul, verific user_id
    BEFORE INSERT on posts
    FOR EACH ROW 
        declare 
            n number(5):=2000;
            uId posts.user_id%type;
            b number(2);
        begin
             dbms_output.put_line('TRIGGER Posts_Trigger');
            
            select id into uId
            from users
            where id = :new.user_id;
            
            select count(1) into b
            from posts;
            
            if b > 0 then
                select max(id) into n
                from posts;
            end if;

            :new.id := n + 1;
            
            
            exception
                when  no_data_found then
                DBMS_OUTPUT.PUT_LINE('Nu exista user cu id-ul dat');
                RAISE_APPLICATION_ERROR(-20000,'Nu exista user cu id ul dat');
            
        end ;
/

create or replace TRIGGER Tags_Trigger
    BEFORE INSERT on tags
    FOR EACH ROW 
        declare 
            n number(5):=3000;
            b number(2);
        begin
             dbms_output.put_line('TRIGGER Tags_Trigger');
            
            select count(1) into b
            from tags;
            
            if b > 0 then
                select max(id) into n
                from tags;
            end if;

            :new.id := n + 1;
            
        end ;
/

create or replace TRIGGER Categories_Trigger
    BEFORE INSERT on categories
    FOR EACH ROW 
        declare 
            n number(5):=4000;
            b number(2);
        begin
        
        dbms_output.put_line('TRIGGER Categories_Trigger');
    
        select count(1) into b
        from categories;
                    
        if b > 0 then
            select max(id) into n
            from categories;
        end if;
        
        :new.id := n + 1;
            
        end ;
  /
  
create or replace TRIGGER update_top_poezii --Trigger la nivel de comanda
    after UPDATE on posts   -- de fiecare data cand se modifica un rating, se poate modifica si topul
    begin
        dbms_output.put_line('TRIGGER Update_Top_Poezii');
        pachet.update_top;
    end;
/
        
create or replace TRIGGER Bookmarked_Posts_Trigger
    before INSERT on bookmarked_posts --de fiecare data cand cineva salveaza un post, postului ii creste rating-ul
    FOR EACH ROW 
        declare 
            pId posts.id%type := :new.post_id;
        begin
        dbms_output.put_line('TRIGGER Bookmarked_Posts_Trigger => Rating Actualization');
            update posts 
            set rating = rating + 1
            where id = pId;
            dbms_output.put_line('rating updatat!');
        end ;
   /
        
create or replace TRIGGER comments_Trigger
    BEFORE INSERT on comments
    FOR EACH ROW 
        declare 
            n number(5):=5000;
            b number(2);
        begin
        
        update posts
        set n_com = n_com + 1
        where id = :new.post_id;
    
        select count(1) into b
        from comments;
                    
        if b > 0 then
            select max(id) into n
            from comments;
        end if;
        
        :new.id := n + 1;
            
        end ;
/

--Pachetul necesar pt actiuni integrate -liniuta 14

create or replace package pachet as --pachetul auxiliar cu obiecte necesare pentru actiuni integrate

    TYPE VEC IS VARRAY(6) OF NUMBER;
    top_poezii VEC; 
    
    procedure update_top;
    procedure afisare_poezie(p_id posts.id%type);
    
    cursor teme_poezii IS
        select p.id, cursor (select distinct c.name
                             FROM post_tag pt, tags t, categories c
                             WHERE  p.id = pt.post_id and pt.tag_id = t.id and t.category_id = c.id
                             order by p.id)
        from posts p;
     
    
end pachet;
/

CREATE OR REPLACE PACKAGE BODY pachet is

    PROCEDURE update_top
        IS
    begin
        
        with vaux as (select  id, rank () over (order by  rating  desc, n_com desc)  as r_num
                      from    posts)
        select  id bulk collect into top_poezii
        from    vaux
        where   r_num  <= 5 and rownum <=5;
        
    end update_top;
    
     PROCEDURE afisare_poezie(p_id posts.id%type)
    is
        post posts%ROWTYPE;
    begin
    
        select * into post
        from posts 
        where id = p_id;
        
        dbms_output.put_line( 'Titlu:' || post.title);
        dbms_output.put_line( 'Content:' || post.content);
        dbms_output.put_line( 'Descriere:' || post.description);
        dbms_output.put_line( 'Rating:' || post.rating);
        dbms_output.put_line( 'Comments:' || post.n_com);
         
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Nu exista postare cu id-ul dat!'); 
                RAISE_APPLICATION_ERROR(-20000,'Nu exista user cu id-ul dat');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('A aparut o eroare!');
                RAISE_APPLICATION_ERROR(-20001, 'A aparut o eroare!');
        
    end afisare_poezie;
    
end pachet;
/

--Inserting:

--Useri:
insert into Users(username,password, last_name, first_name) values ('iuliaa21','parola123','Barbu','Iulia');
insert into Users(username,password, last_name, first_name) values ('Sam22','parola234','Gustin','Samuel');
insert into Users(username,password, last_name, first_name) values ('Adelaida01','parola345','Bara','Adelaida');
insert into Users(username,password, last_name, first_name, role) values ('Admin01','parola456','Dumitru','Andrei','Admin');
insert into Users(username,password, last_name, first_name) values ('Octavian11','parola567','Barbulescu','Octavian');
insert into Users(username,password, last_name, first_name) values ('Sophie14','sophy<3','Tina','Sophia');
insert into Users(username,password, last_name, first_name) values ('Eva_Natalia','parolaSecreta','Garcia','Eva-Natalia');
insert into Users(username,password, last_name, first_name) values ('DavidNick','keep_my_secret','Brown','David-Nicholas');
insert into Users(username,password, last_name, first_name) values ('Ana700','myluv','Smith','Anastasia');

--Posts
--    insert into Posts(user_id, title, content, description) values (1000, 'MyFirstPost','A fost odata ca-n povesti, a fost ca niciodata, din rude mari imparatesti, o prea frumoasa fata!','Versuri din Luceafarul'); --nu exista user cu id ul 1000, triggerul va arunca exceptie
insert into Posts(user_id, title, content, description) values (1001, 'MyFirstPost','A fost odata ca-n povesti, a fost ca niciodata, din rude mari imparatesti, o prea frumoasa fata!','Versuri din Luceafarul');
insert into Posts(user_id, title, content, description) values (1001, 'De ce în al meu suflet','De ce în al meu suflet De ani eu moartea port, De ce mi-e vorba sacã, De ce mi-e ochiul mort?','Versuri preluate din poezia lui Eminescu');    
insert into Posts(user_id, title, content) values (1006, 'In natura','În naturã, ziua toatã,Am plecat ºi noi de-ndatã,La cules de floricele,Sã ne bucurãm de ele.'); 
insert into Posts(user_id, title, content) values (1007, 'Plumb',' Dormea întors amorul meu de plumb, Pe flori de plumb, ?i-am început sã-l strig -, Stam singur lângã mort… ?i era frig…, ?i-i atârnau aripile de plumb.'); 
insert into Posts(user_id, title, content, description) values (1008, 'O poezie geniala', 'Eu nu strivesc corola de minuni a lumii, ºi nu ucid, cu mintea tainele, ce le-ntâlnesc, în calea mea, în flori, în ochi, pe buze ori morminte.', 'poezia care mi-a picat la bac:)');
insert into Posts(user_id, title, content) values (1009, 'Si totusi, iubirea','    Si totusi existã iubire, Si totusi existã blestem, Dau lumii, dau lumii de stire, Iubesc, am curaj si mã tem., Si totusi e stare de veghe, Si totusi murim repetat, Si totusi mai cred în pereche, Si totusi ceva sa-ntâmplat.'); 
insert into Posts(user_id, title, content) values (1003, 'Albinuta','Albinuta Zum Zum Zum, Pleaca la plimbare acum,, Treaba ea si-a terminat, Si-o vacanta ea si-a luat, Vrea sa zboare, drept spre mare, Sa stea intinsa la soare,, Bagajul l-a aranjat,, De nimic nu a uitat.'); 

--Categories
insert into Categories (name) values ('Natura');
insert into Categories (name) values ('Animale');
insert into Categories (name) values ('Filme');
insert into Categories (name) values ('Tristete');
insert into Categories (name) values ('Bucurie');
insert into Categories (name) values ('Din folclor');
insert into Categories (name) values ('Autori Renumiti');
--    insert into Categories (name) values ('Natura'); --va da eroare, datorita unique constraint
insert into Categories (name) values ('Poezii Contemporane');
insert into Categories (name) values ('Iubire');
insert into Categories (name) values ('Filozofie');

--Tags    
insert into tags(category_id,content) values (4001,'flori');
insert into tags(category_id,content) values (4001,'ziua');
insert into tags(category_id,content) values (4001,'copaci');
insert into tags(category_id,content) values (4001,'soare');
insert into tags(category_id,content) values (4007,'Mihai Eminescu');
insert into tags(category_id,content) values (4007,'Lucian Blaga');
insert into tags(category_id,content) values (4007,'George Bacovia');
insert into tags(category_id,content) values (4004,'moarte sufleteasca');
insert into tags(category_id,content) values (4009,'cuplu');
insert into tags(category_id,content) values (4009,'dor');
insert into tags(category_id,content) values (4009,'dragoste');
insert into tags(category_id,content) values (4010,'versuri filozofice');
insert into tags(category_id,content) values (4010,'meditatie filozofica');
insert into tags(category_id,content) values (4010,'revelatii');
insert into tags(category_id,content) values (4010,'ganduri existentiale');
insert into tags(category_id,content) values (4002,'Albine');    
insert into tags(category_id,content) values (4005,'Voie buna');
insert into tags(category_id,content) values (4005,'vacanta');
insert into tags(category_id,content) values (4008,'contemporan');
        
--Post_Tags
insert into Post_tag(post_id, tag_id) values ( 2003,3001);
insert into Post_tag(post_id, tag_id) values ( 2003,3009);
insert into Post_tag(post_id, tag_id) values ( 2002,3007);
insert into Post_tag(post_id, tag_id) values ( 2002,3006);
insert into Post_tag(post_id, tag_id) values ( 2002,3004);
insert into Post_tag(post_id, tag_id) values ( 2002,3008); 
--    insert into Post_tag(post_id, tag_id) values ( 2002,3008); --un exemplu  care nu va merge, datorita unique constraint 
insert into Post_tag(post_id, tag_id) values ( 2004,3011); 
insert into Post_tag(post_id, tag_id) values ( 2004,3006); 
insert into Post_tag(post_id, tag_id) values ( 2005,3012); 
insert into Post_tag(post_id, tag_id) values ( 2005,3013); 
insert into Post_tag(post_id, tag_id) values ( 2005,3014); 
insert into Post_tag(post_id, tag_id) values ( 2005,3015); 
insert into Post_tag(post_id, tag_id) values ( 2005,3016); 
insert into Post_tag(post_id, tag_id) values ( 2006,3009); 
insert into Post_tag(post_id, tag_id) values ( 2006,3006);
insert into Post_tag(post_id, tag_id) values ( 2007,3004);
insert into Post_tag(post_id, tag_id) values ( 2007,3002);
insert into Post_tag(post_id, tag_id) values ( 2007,3017);
insert into Post_tag(post_id, tag_id) values ( 2007,3018);
insert into Post_tag(post_id, tag_id) values ( 2007,3019);

--Comments
insert into Comments(user_id, post_id, content) values ( 1002, 2001, 'Ce frumos!');
insert into Comments(user_id, post_id, content) values ( 1003, 2004, 'Foarte profund..');
insert into Comments(user_id, post_id, content) values ( 1005, 2004, 'Asta este o pozie pe cat de cunoscuta pe atat de buna! Ma bucur ca ai postat-o.');
insert into Comments(user_id, post_id, content) values ( 1007, 2005, 'Si mie mi-a picat la bac! ce tare!');
insert into Comments(user_id, post_id, content) values ( 1006, 2005, 'uff am urat poezia asta in liceu..');
insert into Comments(user_id, post_id, content) values ( 1003, 2005, 'O poezie foarte abstracta!');
insert into Comments(user_id, post_id, content) values ( 1001, 2006, 'romantic!');
insert into Comments(user_id, post_id, content) values ( 1002, 2006, 'Aproape am plans la poezia aceasta!');


--Bookmarked_Posts
insert into Bookmarked_Posts(user_id, post_id) values (1002,2002);
insert into Bookmarked_Posts(user_id, post_id) values (1002,2006);
insert into Bookmarked_Posts(user_id, post_id) values (1006,2007);
insert into Bookmarked_Posts(user_id, post_id) values (1006,2003);
insert into Bookmarked_Posts(user_id, post_id) values (1006,2001);
insert into Bookmarked_Posts(user_id, post_id) values (1005,2004);
insert into Bookmarked_Posts(user_id, post_id) values (1008,2001);
insert into Bookmarked_Posts(user_id, post_id) values (1001,2002);
insert into Bookmarked_Posts(user_id, post_id) values (1003,2004);
insert into Bookmarked_Posts(user_id, post_id) values (1001,2005);
insert into Bookmarked_Posts(user_id, post_id) values (1008,2007);
insert into Bookmarked_Posts(user_id, post_id) values (1003,2007);
insert into Bookmarked_Posts(user_id, post_id) values (1008,2002);
insert into Bookmarked_Posts(user_id, post_id) values (1008,2003);

delete 
from Bookmarked_Posts 
where user_id = 1008 and post_id = 2003;

select * from bookmarked_posts;

--Rezolvari, pachet principal:

CREATE OR REPLACE PACKAGE proiect AS --pachetul principal: are rolul de a genera informatii suplimentare pentru site(determina pt fiecare profil stilul unui user, ii face o recomandare, iar pentru pagina principala a site ului genereaza un top 5 best rated posts)
    PROCEDURE afisare_top;
    PROCEDURE recomandare_user(u_id users.id%type);
    FUNCTION tema_predominanta(u_id users.id%type) RETURN categories.name%type;
    PROCEDURE profiluri_useri;
    
END proiect;
/
    
CREATE OR REPLACE PACKAGE BODY proiect is 
    
    PROCEDURE afisare_top
    is
        i number(5);
    begin
        FOR i IN pachet.top_poezii.FIRST.. pachet.top_poezii.LAST 
        LOOP
            dbms_output.put_line(chr(10) || 'Locul' || i || ':' || chr(10));
            pachet.afisare_poezie(pachet.top_poezii(i));
        end loop;
    end afisare_top;

    FUNCTION tema_predominanta(u_id users.id%type)
        RETURN categories.name%type
        IS
            TYPE dictionary_type IS TABLE OF number INDEX BY VARCHAR2(30);
            frecv dictionary_type;
                        
            type type1 is table of categories.name%type;
            c_names type1;
            
            type type2 is table of posts.id%type; --id urile posturilor postate de user
            up_ids type2;
            
            TYPE refcursor IS REF CURSOR;
            categorii refcursor;
            
            categorie categories.name%type;
            postare_id posts.id%type;
            
            maxim number := -1;
            nume  categories.name%type;
            recomandare_finala posts.id%type;
    begin

        select name bulk collect into c_names
        from categories;
        
        select id bulk collect into up_ids
        from posts
        where user_id = u_id;
        
        for i in 1..c_names.count loop --initializez vectorul de frecventa
            frecv(c_names(i)) := 0;
        end loop;
    
        open pachet.teme_poezii;
        loop
        fetch pachet.teme_poezii into postare_id, categorii;
        exit when pachet.teme_poezii%NOTFOUND;
        
            if(postare_id member of up_ids) --daca poezia a fost apreciata de user
            then
                loop
                    fetch categorii into categorie;
                    exit when categorii%NOTFOUND;
                        frecv(categorie) := frecv(categorie) + 1;
                end loop;
                        
            end if;
            
        end loop;
        close pachet.teme_poezii;
        
        maxim := -1;
        
        for i in 1..c_names.count loop 
            if (maxim < frecv(c_names(i))) then
                maxim := frecv(c_names(i)); 
                nume := c_names(i);    
            end if;
        end loop;
        
        return nume;
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Nu exista user cu id-ul dat!'); 
                RAISE_APPLICATION_ERROR(-20000,'Nu exista user cu id-ul dat');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('A aparut o eroare!');
                RAISE_APPLICATION_ERROR(-20001, 'A aparut o eroare!');
        
        --Atentie: nu e nevoie de when too_many_rows, pentru ca am triggerul care se asigura ca niciodata nu vor exista mai multi useri cu acelasi id
        
    end tema_predominanta;
    
    PROCEDURE recomandare_user(u_id users.id%type)
        IS
            TYPE dictionary_type IS TABLE OF number INDEX BY VARCHAR2(30);
            frecv dictionary_type;
                        
            type type1 is table of categories.name%type;
            c_names type1;
            
            type type2 is table of posts.id%type; --id urile posturilor salvate de user
            bp_ids type2;
            
            TYPE refcursor IS REF CURSOR;
            categorii refcursor;
            
            categorie categories.name%type;
            postare_id posts.id%type;
            
            s number;
            maxim number := -1;
            recomandare_finala posts.id%type;
    begin

        select name bulk collect into c_names
        from categories;
        
        select post_id bulk collect into bp_ids
        from bookmarked_posts
        where user_id = u_id;
        
        for i in 1..c_names.count loop --initializez vectorul de frecventa
            frecv(c_names(i)) := 0;
        end loop;
    
        open pachet.teme_poezii;
        loop
        fetch pachet.teme_poezii into postare_id, categorii;
        exit when pachet.teme_poezii%NOTFOUND;
        
            if(postare_id member of bp_ids) --daca poezia a fost apreciata de user
            then
                loop
                    fetch categorii into categorie;
                    exit when categorii%NOTFOUND;
                        frecv(categorie) := frecv(categorie) + 1;
                end loop;
                        
            end if;
            
        end loop;
        close pachet.teme_poezii;  
        open pachet.teme_poezii;-- il deschid din nou
        loop
        fetch pachet.teme_poezii into postare_id, categorii;
        exit when pachet.teme_poezii%NOTFOUND;
        
            if(postare_id not member of bp_ids) --de data asta caut in poeziile care nu au fost inca salvate de user
            then
                s := 0;
                loop
                    fetch categorii into categorie;
                    exit when categorii%NOTFOUND;
                        s := s + frecv(categorie);
                end loop;
                
                if(s > maxim) then
                    maxim := s;
                    recomandare_finala := postare_id;
                end if;
                        
            end if;
            
        end loop;
        
        close pachet.teme_poezii;   
        
        pachet.afisare_poezie(recomandare_finala);
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Nu exista user cu id-ul dat!'); 
                RAISE_APPLICATION_ERROR(-20000,'Nu exista user cu id-ul dat');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('A aparut o eroare!');
                RAISE_APPLICATION_ERROR(-20001, 'A aparut o eroare!');
        
    end recomandare_user;
    
    
    PROCEDURE profiluri_useri
    is
        type type1 is table of users%rowtype;
        us type1;
        
    begin
        select * bulk collect into us
        from users;
        
        for i in 1.. us.count loop
            dbms_output.put_line(chr(10)|| chr(10) || 'User:' || chr(10) || us(i).last_name || ' ' || us(i).first_name || chr(10));
            dbms_output.put_line( 'In stilul userului predomina:' || chr(10) || tema_predominanta(us(i).id) || chr(10));
            dbms_output.put_line( 'O postare care l-ar putea interesa si pe care nu a salvat-o inca:');
            recomandare_user(us(i).id);
        end loop;
        
    end profiluri_useri;
    
    
end proiect;
/

--Apelari:

begin
    dbms_output.put_line('Pe prima pagina a site-ului se va afisa topul celor mai apreciate postari:');
    proiect.afisare_top;

    dbms_output.put_line(chr(10)|| chr(10) ||'Userilor li se va afisa pe profil tema predominanta a poeziilor postate de ei si o recomandare in functie de ce au apreciat pana in prezent:');
    proiect.profiluri_useri;
end;
/
-- Restrictii:
create or replace TRIGGER No_Drop_Permission --Trigger ldd
    before drop on database
    begin
            DBMS_OUTPUT.PUT_LINE('No drop permission!');
            RAISE_APPLICATION_ERROR(-20003, 'No drop permission!');
    end;
/
--test:

select * from users;















