-- msolutions script

-- creazione database
/*
create database msolutions
	with
	owner = postgres
	encoding = 'utf8'
	connection limit = -1;
*/

-- eliminazione eventuali tabelle ed enum già presenti

drop table if exists partecipazione;
drop table if exists interessamento;
drop table if exists consulenza;
drop table if exists pagamento;
drop table if exists aggiornamento;
drop table if exists licenza;
drop table if exists trattativa;
drop table if exists attivita;
drop table if exists email;
drop table if exists telefono;
drop table if exists contatto;
drop table if exists azienda;
drop table if exists versione;
drop table if exists responsabile;
drop table if exists sviluppatore;
drop table if exists consulente;
drop table if exists commerciale;
drop table if exists impiegato;
drop table if exists prodotto;
drop table if exists sede;

drop type if exists tipo_prodotto;
drop type if exists tipo_impiegato;
drop type if exists tipo_attivita;
drop type if exists tipo_consulenza;

-- creazione tabelle

create table sede (
	citta varchar(100) primary key
);

create type tipo_prodotto as enum('Contabilita', 'Magazzino', 'Budgeting');

create table prodotto (
	nome varchar(20) primary key,
	canone_standard decimal(10,2) not null,
	tipo tipo_prodotto not null
);

create type tipo_impiegato as enum('Dipendente', 'Libero professionista');

create table impiegato (
	codice char(6) primary key,
	nome varchar(100) not null,
	cognome varchar(100) not null,
	codice_fiscale char(16) not null unique,
	data_nascita date not null,
	via varchar(100) not null,
	civico varchar(5) not null,
	citta varchar(100) not null,
	cap char(5) not null,
	stipendio_lordo decimal(10,2) not null,
	data_inizio_rapporto date not null default now(),
	data_fine_rapporto date null,
	tipo tipo_impiegato not null,
	partita_iva char(11) null unique,
	livello smallint null,
	sede varchar(100) not null,
	foreign key (sede) references sede(citta)
		on update cascade on delete cascade
);

create table commerciale (
	impiegato char(6) primary key,
	regione varchar(50) not null,
	foreign key (impiegato) references impiegato(codice)
		on update cascade on delete cascade
);

create table consulente (
	impiegato char(6) primary key,
	foreign key (impiegato) references impiegato(codice)
		on update cascade on delete cascade
);

create table sviluppatore (
	impiegato char(6) primary key,
	prodotto varchar(20) not null,
	foreign key (impiegato) references impiegato(codice)
		on update cascade on delete cascade,
	foreign key (prodotto) references prodotto(nome)
		on update cascade on delete cascade
);

create table responsabile (
	impiegato char(6) primary key,
	sede varchar(100) not null,
	foreign key (impiegato) references impiegato(codice)
		on update cascade on delete cascade,
	foreign key (sede) references sede(citta)
		on update cascade on delete cascade
);

create table versione (
	codice char(6) primary key,
	data_rilascio date not null default now(),
	prodotto varchar(20) not null,
	foreign key (prodotto) references prodotto(nome)
		on update cascade on delete cascade
);

create table azienda (
	partita_iva char(11) primary key,
	ragione_sociale varchar(100) not null,
	sede_legale varchar(100) not null,
	rea char(9) not null unique,
	pec varchar(100) not null
);

create table contatto (
	codice int primary key,
	nome varchar(100) not null,
	cognome varchar(100) not null,
	data_scadenza_consenso_trattamento_dati date not null,
	origine varchar(20) not null,
	commerciale char(6) null,
	azienda char(11) not null,
	foreign key (commerciale) references commerciale(impiegato)
		on update cascade on delete cascade,
	foreign key (azienda) references azienda(partita_iva)
		on update cascade on delete cascade
);

create table telefono (
	contatto int not null,
	numero varchar(20) not null,
	primary key (contatto, numero),
	foreign key (contatto) references contatto(codice)
		on update cascade on delete cascade
);

create table email (
	contatto int not null,
	indirizzo varchar(100) not null,
	primary key (contatto, indirizzo),
	foreign key (contatto) references contatto(codice)
		on update cascade on delete cascade
);

create type tipo_attivita as enum('Appuntamento', 'Telefonata', 'Email');

create table attivita (
	codice int primary key,
	data date not null default now(),
	descrizione varchar(100) null,
	tipo tipo_attivita not null,
	contatto int not null,
	commerciale char(6) not null,
	prodotto varchar(20) not null,
	foreign key (contatto) references contatto(codice)
		on update cascade on delete cascade,
	foreign key (commerciale) references commerciale(impiegato)
		on update cascade on delete cascade,
	foreign key (prodotto) references prodotto(nome)
		on update cascade on delete cascade
);

create table trattativa (
	attivita int primary key,
	data_inizio date not null default now(),
	data_chiusura date null,
	canone_previsto decimal(10,2) not null,
	commerciale char(6) not null,
	foreign key (attivita) references attivita(codice)
		on update cascade on delete cascade,
	foreign key (commerciale) references commerciale(impiegato)
		on update cascade on delete cascade
);

create table licenza (
	codice_contratto char(6) primary key,
	data_attivazione date not null default now(),
	data_disdetta date null,
	canone decimal(10,2) not null,
	azienda char(11) not null,
	versione char(6) not null,
	trattativa int not null,
	foreign key (azienda) references azienda(partita_iva)
		on update cascade on delete cascade,
	foreign key (versione) references versione(codice)
		on update cascade on delete cascade,
	foreign key (trattativa) references trattativa(attivita)
		on update cascade on delete cascade
);

create table aggiornamento (
	licenza char(6) not null,
	versione_iniziale char(6) not null,
	versione_aggiornata char(6) not null,
	data date not null default now(),
	primary key (licenza, versione_iniziale),
	foreign key (licenza) references licenza(codice_contratto)
		on update cascade on delete cascade,
	foreign key (versione_iniziale) references versione(codice)
		on update cascade on delete cascade,
	foreign key (versione_aggiornata) references versione(codice)
		on update cascade on delete cascade
);

create table pagamento (
	licenza char(6) not null,
	data date not null default now(),
	importo decimal(10,2) not null,
	primary key (licenza, data),
	foreign key (licenza) references licenza(codice_contratto)
		on update cascade on delete cascade
);

create type tipo_consulenza as enum('In sede', 'Da remoto');

create table consulenza (
	contatto int not null,
	consulente char(6) not null,
	prodotto varchar(20) not null,
	data_pianificata date not null,
	data_effettiva date null,
	tipo tipo_consulenza not null,
	descrizione varchar(100) null,
	primary key (contatto, consulente, prodotto, data_pianificata),
	foreign key (contatto) references contatto(codice)
		on update cascade on delete cascade,
	foreign key (consulente) references consulente(impiegato)
		on update cascade on delete cascade,
	foreign key (prodotto) references prodotto(nome)
		on update cascade on delete cascade
);

create table interessamento (
	prodotto varchar(20) not null,
	contatto int not null,
	data date not null default now(),
	primary key (prodotto, contatto),
	foreign key (prodotto) references prodotto(nome)
		on update cascade on delete cascade,
	foreign key (contatto) references contatto(codice)
		on update cascade on delete cascade
);

create table partecipazione (
	contatto int not null,
	trattativa int not null,
	ruolo varchar(20) not null,
	primary key (contatto, trattativa),
	foreign key (contatto) references contatto(codice)
		on update cascade on delete cascade,
	foreign key (trattativa) references trattativa(attivita)
		on update cascade on delete cascade
);

-- inserimento dati

insert into sede(citta) 
values ('Padova'), ('Milano'), ('Brescia');

insert into prodotto(nome, canone_standard, tipo)
values ('Grade', 129.90, 'Contabilita'), ('Penta', 69.90, 'Contabilita'), ('Alerts', 39.90, 'Magazzino'), ('Plus', 29.90, 'Contabilita'), ('Bazar', 89.90, 'Budgeting'), ('Domino', 49.90, 'Contabilita'), ('Shore', 39.90, 'Magazzino'), ('Exceed', 19.90, 'Budgeting'), ('Century', 199.90, 'Contabilita'), ('Lambda', 19.90, 'Magazzino'), ('Eco', 219.90, 'Budgeting'), ('Gram', 19.90, 'Budgeting');

insert into impiegato(codice, nome, cognome, codice_fiscale, data_nascita, via, civico, citta, cap, stipendio_lordo, data_inizio_rapporto, data_fine_rapporto, tipo, partita_iva, livello, sede)
values ('AK73GE', 'Graziella', 'Gazza', 'GZZGZL69S53F743C', '1969-11-13', 'Via Angolo', '5/A', 'Padova', '35131', 39485.00, '2012-12-21', null, 'Dipendente', null, 2, 'Padova'), ('BY26GW', 'Ottavia', 'Bolzoni', 'BLZTVC82B61A692R', '1982-01-20', 'Via Disco', '42', 'Padova', '35135', 28172.00, '2013-01-14', null, 'Dipendente', null, 2, 'Padova'), ('HE89NS', 'Giovanni', 'De Felice', 'DFLGNN99E27H222C', '1999-05-27', 'Via Seta', '11', 'Padova', '35128', 22312.00, '2019-04-30', '2021-07-30', 'Dipendente', null, 5, 'Padova'), ('JE76SB', 'Dafne', 'Zanforlin', 'ZNFDFN87M50B924F', '1989-08-10', 'Via Quadro', '36/C', 'Padova', '35143', 26424.00, '2016-04-30', null, 'Libero professionista', '71144220366', null, 'Padova'), ('UH66WB', 'Alfeo', 'Schiavonetti', 'SCHLGS87D18F712A', '1987-04-18', 'Via Talco', '89', 'Milano', '20123', 21652.00, '2020-10-17', null, 'Dipendente', null, 4, 'Milano'), ('NS91JS', 'Giuseppe', 'Demba', 'DMBGPP78A31M162R', '1978-01-31', 'Via Ghiaccio', '3', 'Milano', '20127', 27519.00, '2015-02-19', null, 'Dipendente', null, 2, 'Milano'), ('MS73LP', 'Denis', 'Rampone', 'RMPDNS00C09E927F', '2000-03-09', 'Via Disegno', '26/A', 'Milano', '20127', 27223.00, '2016-07-06', null, 'Dipendente', null, 3, 'Milano'), ('KS73B2', 'Angioletta', 'Mancinelli', 'MNCNLT75D42G603I', '1975-04-02', 'Via Calice', '56', 'Brescia', '25127', 36598.00, '2014-11-04', null, 'Dipendente', null, 2, 'Brescia'), ('NM34HL', 'Consuelo', 'Tafa', 'TFACSL74M59I711G', '1974-08-18', 'Via Alba', '18', 'Brescia', '25136', 24598.00, '2018-09-27', null, 'Dipendente', null, 4, 'Brescia'), ('AF59NQ', 'Bernarda', 'Perraro', 'PRRBNR98M62C126N', '1998-08-22', 'Via Sapienza', '9', 'Brescia', '25122', 26724.00, '2019-11-14', null, 'Libero professionista', 30825410035, null, 'Brescia'), ('JA73BW', 'Elena', 'Cappellina', 'CPPLVN70L55F030C', '1970-07-15', 'Via Pane', '9', 'Padova', '35143', 27314.00, '2015-03-28', null, 'Dipendente', null, 3, 'Padova'), ('FU30SX', 'Franco', 'Capaccio', 'FFNVCN92S24I815T', '1992-07-16', 'Via Suola', '72', 'Padova', '35142', 23293.00, '2019-12-03', null, 'Dipendente', null, 4, 'Padova');

insert into commerciale(impiegato, regione)
values ('NM34HL', 'Lombardia'), ('MS73LP', 'Lombardia'), ('UH66WB', 'Piemonte'), ('AK73GE', 'Veneto');

insert into consulente(impiegato)
values ('AF59NQ'), ('HE89NS');

insert into sviluppatore(impiegato, prodotto)
values ('JE76SB', 'Century'), ('JA73BW', 'Eco'), ('FU30SX', 'Century');

insert into responsabile(impiegato, sede)
values ('KS73B2', 'Brescia'), ('NS91JS', 'Milano'), ('BY26GW', 'Padova');

insert into versione(codice, data_rilascio, prodotto)
values ('GR01GR', '2014-07-19', 'Grade'),('GR02GR', '2015-02-21', 'Grade'), ('CE01CE', '2015-07-21', 'Century'), ('CE02CE', '2016-08-14', 'Century'), ('PL01PL', '2017-02-16', 'Plus'), ('GR03GR', '2018-03-02', 'Grade'), ('BA01BA', '2018-11-18', 'Bazar'), ('PL02PL', '2019-12-05', 'Plus'), ('EC01EC', '2019-04-23', 'Eco'), ('AL01AL', '2019-06-13', 'Alerts'), ('LA01LA', '2020-02-07', 'Lambda'), ('SH01SH', '2020-02-12', 'Shore'), ('CE03CE', '2020-12-05', 'Century'), ('PE01PE', '2020-09-19', 'Penta'), ('GR04GR', '2020-08-14', 'Grade'), ('BA02BA', '2020-01-14', 'Bazar'), ('DO01DO', '2021-04-17', 'Domino'), ('SH02SH', '2021-05-24', 'Shore'), ('EX01EX', '2021-06-02', 'Exceed'), ('GM01GM', '2021-05-26', 'Gram'), ('EC02EC', '2021-07-10', 'Eco'), ('LA02LA', '2021-07-26', 'Lambda'), ('LA03LA', '2021-08-14', 'Lambda');

insert into azienda(partita_iva, ragione_sociale, sede_legale, rea, pec)
values ('32630430935', 'Quantum S.R.L.', 'Via Abete 25, 30100 Venezia', '630430935', 'amministrazione@quantum.it'), ('66782820212', 'Bersaglio S.N.C.', 'Via Gelso 12, 31010 Treviso', '782820212', 'amministrazione@bersaglio.it'), ('17369960913', 'Orbita S.R.L.', 'Via Nespolo 91, 31010 Treviso', '369960913', 'pec@orbita.it'), ('73403710624', 'Indovinello S.R.L.', 'Via Acacia 2, 35010 Padova', '403710624', 'amministrazione@indovinello.it'), ('65054781201', 'Ultra S.P.A.', 'Via Pino 35, 33010 Udine', '054781201', 'amministrazione@ultra.it'), ('51995790121', 'Nordico S.R.L.', 'Via Ulivo 23, 35010 Padova', '995790121', 'pec@nordico.it'), ('42736640543', 'Connettere S.R.L.', 'Via Corniolo 16, 34010 Trieste', '736640543', 'legale@connettere.it'), ('47392470861', 'Scacco matto S.R.L.', 'Via Pero 54, 34010 Trieste', '392470861', 'pec@scaccomatto.it'), ('54092440640', 'Delizie S.R.L.', 'Via Sambuco 14, 32010 Belluno', '092440640', 'pec@delizie.it');

insert into contatto(codice, nome, cognome, data_scadenza_consenso_trattamento_dati, origine, commerciale, azienda)
values (12, 'Massimiliano', 'Pagnotto', '2023-12-12', 'passaparola', null, '32630430935'), (21, 'Ludovico', 'Fanucci', '2021-11-28', 'passaparola', null, '32630430935'), (31, 'Attilio', 'Longo', '2022-07-08', 'volantino', null, '42736640543'), (38, 'Cipriano', 'Genovesi', '2022-11-18', 'volantino', null, '32630430935'), (41, 'Ermenegilda', 'Mazzi', '2022-01-15', 'pubblicità radio', 'AK73GE', '66782820212'), (48, 'Bartolomeo', 'Romano', '2022-09-12', 'pubblicità radio', null, '47392470861'), (56, 'Alessia', 'Pugliesi', '2021-12-13', 'passaparola', null, '66782820212'), (64, 'Odetta', 'Trentini', '2022-03-14', 'campagna social', null, '17369960913'), (72, 'Arcangela', 'Lucchese', '2022-04-18', 'passaparola', null, '54092440640'), (78, 'Alfreda', 'Mancini', '2021-12-24', 'passaparola', 'AK73GE', '73403710624'), (87, 'Brunilde', 'Russo', '2023-04-14', 'campagna social', null, '65054781201'), (93, 'Norberto', 'Padovesi', '2022-11-17', 'volantino', 'MS73LP', '51995790121');

insert into telefono(contatto, numero)
values (12, '347 2638263'), (21, '372 9384733'), (38, '362 7495748'), (41, '362 7384753'), (56, '346 2163354'), (64, '392 1723944'), (78, '346 2736495'), (87, '346 5647392'), (93, '392 1724356'), (31, '342 3728495'), (48, '346 2376485'), (72, '346 2738292');

insert into email(contatto, indirizzo)
values (12, 'massimiliano@gmail.com'), (21, 'ludovico@gmail.com'), (38, 'cipriano@alice.it'), (41, 'ermenegilda@libero.it'), (56, 'alessia@gmail.com'), (64, 'odetta@alice.it'), (78, 'alfreda@gmail.com'), (87, 'brunilde@gmail.com'), (93, 'norberto@libero.it'), (31, 'attilio@gmail.com'), (48, 'bartolomeo@gmail.com'), (72, 'arcangela@gmail.com');

insert into attivita(codice, data, descrizione, tipo, contatto, commerciale, prodotto)
values (13, '2021-01-14', 'visitato il cliente in sede', 'Appuntamento', 12, 'NM34HL', 'Eco'), (14, '2021-02-15', null, 'Telefonata', 21, 'NM34HL', 'Grade'), (16, '2021-04-23', null, 'Appuntamento', 72, 'UH66WB', 'Domino'), (24, '2021-03-21', null, 'Appuntamento', 38, 'NM34HL', 'Gram'), (25, '2021-06-14', null, 'Telefonata', 21, 'NM34HL', 'Exceed'), (31, '2021-04-04', 'fatta la demo presso il cliente', 'Appuntamento', 21, 'NM34HL', 'Penta'), (36, '2021-07-26', 'chiamato per proporre software', 'Telefonata', 21, 'NM34HL', 'Plus'), (41, '2021-07-03', 'il cliente sembra intenzionato a comprare', 'Appuntamento', 56, 'UH66WB', 'Grade'), (43, '2021-07-04', 'il cliente non è convinto ha bisogno di incoraggiamento', 'Telefonata', 56, 'UH66WB', 'Penta'), (44, '2021-03-16', null, 'Email', 93, 'MS73LP', 'Century'), (47, '2021-07-08', null, 'Telefonata', 72, 'NM34HL', 'Grade'), (48, '2021-07-09', null, 'Email', 72, 'NM34HL', 'Penta'), (54, '2021-03-18', 'mandato il video con la demo', 'Email', 93, 'MS73LP', 'Century'), (55, '2021-07-01', null, 'Email', 78, 'MS73LP', 'Century'), (57, '2021-07-03', null, 'Email', 78, 'MS73LP', 'Plus'), (59, '2021-07-04', null, 'Appuntamento', 78, 'MS73LP', 'Shore'), (62, '2021-06-11', null, 'Email', 87, 'MS73LP', 'Bazar'), (70, '2021-07-09', null, 'Email', 87, 'MS73LP', 'Century'),(73, '2021-07-12', null, 'Email', 87, 'MS73LP', 'Plus'), (79, '2021-04-16', null, 'Appuntamento', 41, 'AK73GE', 'Lambda'), (83, '2021-05-04', null, 'Telefonata', 78, 'AK73GE', 'Shore'), (90, '2021-04-11', null, 'Appuntamento', 72, 'UH66WB', 'Alerts');

insert into trattativa(attivita, data_inizio, data_chiusura, canone_previsto, commerciale)
values (13, '2021-01-30', '2021-05-14', 219.90, 'NM34HL'), (16, '2021-05-22', '2021-05-23', 49.90, 'NM34HL'), (31, '2021-05-05', '2021-05-14', 59.90, 'MS73LP'), (41, '2021-07-15', '2021-07-18', 119.90, 'UH66WB'), (43, '2021-07-17', '2021-07-19', 69.90, 'UH66WB'), (47, '2021-07-18', '2021-07-23', 129.90, 'NM34HL'), (48, '2021-07-19', '2021-07-22', 49.90, 'NM34HL'), (54, '2021-04-20', '2021-04-24', 179.90, 'MS73LP'), (55, '2021-07-11', '2021-07-12', 199.90, 'MS73LP'), (57, '2021-07-13', '2021-07-15', 29.90, 'MS73LP'), (59, '2021-07-14', '2021-07-16', 39.90, 'MS73LP'), (70, '2021-07-19', '2021-07-27', 199.90, 'MS73LP'), (73, '2021-07-22', '2021-07-30', 29.90, 'MS73LP'), (79, '2021-05-18', '2021-06-11', 19.90, 'AK73GE'), (36, '2021-08-02', null, 29.90, 'NM34HL');

insert into licenza(codice_contratto, data_attivazione, data_disdetta, canone, azienda, versione, trattativa)
values ('HDB273', '2021-06-01', null, 219.90, '32630430935', 'EC02EC', 13), ('BAJ283', '2021-05-01', '2021-06-30', 169.90, '51995790121', 'CE03CE', 54), ('HKR739', '2021-07-01', NULL, 19.90, '66782820212', 'LA01LA', 79), ('WBE633', '2021-06-01', NULL, 39.90, '54092440640', 'DO01DO', 16), ('AHW628', '2021-08-01', NULL, 109.90, '66782820212', 'GR04GR', 41), ('NSW283', '2021-08-01', NULL, 69.90 , '66782820212', 'PE01PE', 43), ('ADL237', '2021-08-01', NULL, 129.90, '54092440640', 'GR04GR', 47), ('LHI675', '2021-08-01', NULL, 59.90, '54092440640', 'PE01PE', 48), ('JSN263', '2021-08-01', NULL, 199.90, '73403710624', 'CE03CE', 55), ('PPW234', '2021-08-01', '2021-08-31', 19.90, '73403710624', 'PL02PL', 57), ('BHF526', '2021-08-01', NULL, 39.90, '73403710624', 'SH02SH', 59), ('PYI230', '2021-08-01', NULL, 199.90, '65054781201', 'CE03CE', 70), ('ZWA237', '2021-08-01', NULL, 29.90, '65054781201', 'PL02PL', 73);

insert into aggiornamento(licenza, versione_iniziale, versione_aggiornata, data)
values ('HDB273', 'EC01EC', 'EC02EC', '2021-07-11');

insert into pagamento(licenza, data, importo)
values ('HDB273', '2021-06-10', 219.90), ('HDB273', '2021-07-10', 219.90), ('HDB273', '2021-08-10', 219.90), ('BAJ283', '2021-05-10', 169.90), ('BAJ283', '2021-06-10', 169.90), ('HKR739', '2021-07-10', 19.90), ('WBE633', '2021-06-10', 39.90), ('WBE633', '2021-07-10', 39.90), ('AHW628', '2021-08-10', 109.90), ('NSW283', '2021-08-10', 69.90), ('ADL237', '2021-08-10', 129.90), ('JSN263', '2021-08-10', 199.90), ('PPW234', '2021-08-10', 19.90), ('BHF526', '2021-08-10', 39.90), ('ZWA237', '2021-08-10', 29.90);

insert into consulenza(contatto, consulente, prodotto, data_pianificata, data_effettiva, tipo, descrizione)
values (21, 'HE89NS', 'Eco', '2021-07-14', '2021-07-15', 'In sede', 'il cliente si ostina a non capire le basi del programma non ne posso più mi licenzio'), (21, 'AF59NQ', 'Eco', '2021-08-11', '2021-08-11', 'Da remoto', 'rispiegate le funzionalità di base'), (93, 'AF59NQ', 'Century', '2021-09-21', null, 'Da remoto', null);

insert into interessamento(prodotto, contatto, data)
values ('Eco', 21, '2021-01-12'), ('Lambda', 21, '2021-08-24'), ('Alerts', 21, '2021-08-24'), ('Century', 93, '2021-03-11'), ('Gram', 93, '2021-08-14'), ('Shore', 78, '2021-05-03'), ('Penta', 48, '2021-08-11');

insert into partecipazione(contatto, trattativa, ruolo)
values (12, 13, 'acquirente'), (21, 13, 'oppositore'),(38, 13, 'utente'), (93, 54, 'acquirente'), (41, 79, 'acquirente'), (56, 79, 'utente'), (12, 36, 'acquirente'), (21, 36, 'utente'), (12, 31, 'acquirente'), (21, 31, 'utente'), (38, 31, 'utente'), (72, 16, 'acquirente'), (56, 41, 'acquirente'), (56, 43, 'acquirente'), (72, 47, 'acquirente'), (72, 48, 'acquirente') ,(78, 55, 'acquirente') ,(78, 57, 'acquirente') ,(78, 59, 'acquirente') ,(87, 70, 'acquirente') ,(87, 73, 'acquirente');

-- creazione indici

DROP INDEX IF EXISTS Idx_Contatto;
CREATE INDEX Idx_Contatto ON Contatto(Cognome, Nome);

/*
SELECT * 
FROM Contatto
WHERE Cognome = 'Mancini' AND Nome = 'Alfreda'
*/

-- query sql
/*
1. Mostrare, per tutti i prodotti, gli incassi totali del mese di agosto 2021, fare una stima degli incassi per settembre 2021 in base alle licenze attive e ai rispettivi canoni, ordinando i risultati per tipo prodotto e successivamente dall'incasso previsto più alto a quello più basso.

SELECT P.Nome, P.Tipo, COALESCE(TI.Totale_incassato_agosto, 0) Totale_incassato_agosto, COALESCE(IP.Incassi_previsti_settembre, 0) Incassi_previsti_settembre
FROM Prodotto P
LEFT JOIN (
	SELECT V.Prodotto, SUM(P.Importo) Totale_incassato_agosto
	FROM Pagamento P
	INNER JOIN Licenza L ON L.Codice_contratto = P.Licenza
	INNER JOIN Versione V ON V.Codice = L.Versione
	WHERE P.Data >= '2021-08-01' AND P.Data <= '2021-08-31'
	GROUP BY V.Prodotto
) TI ON TI.Prodotto = P.Nome
LEFT JOIN (
	SELECT V.Prodotto, SUM(L.Canone) Incassi_previsti_settembre
	FROM Licenza L
	INNER JOIN Versione V ON V.Codice = L.Versione
	WHERE L.Data_disdetta IS NULL OR L.Data_disdetta >= '2021-09-01'
	GROUP BY V.Prodotto
) IP ON IP.Prodotto = P.Nome
ORDER BY P.Tipo, COALESCE(IP.Incassi_previsti_settembre, 0) DESC;

2. Mostrare l'elenco delle licenze attive ma non ancora aggiornate all'ultima versione disponibile, assieme alla ragione sociale dell'azienda licenziataria, nome del software in questione, versione attuale e versione disponibile per l'aggiornamento, ordinando i risultati in base alla ragione sociale.

DROP VIEW IF EXISTS Ultime_versioni CASCADE;
CREATE VIEW Ultime_versioni(Prodotto, Versione)
AS (
	SELECT V.Prodotto, V.Codice
	FROM Versione V
	INNER JOIN (
		SELECT Prodotto, MAX(Data_rilascio) Data_rilascio
		FROM Versione
		GROUP BY Prodotto
	) U ON U.Prodotto = V.Prodotto AND U.Data_rilascio = V.Data_rilascio
);

SELECT L.Codice_contratto, A.Ragione_sociale, V.Prodotto, V.Codice Versione_attuale, U.Versione Versione_disponibile
FROM Licenza L
INNER JOIN Azienda A ON A.Partita_IVA = L.Azienda
INNER JOIN Versione V ON V.Codice = L.Versione
INNER JOIN Ultime_versioni U ON U.Prodotto = V.Prodotto
WHERE (L.Data_disdetta IS NULL OR L.Data_disdetta > NOW())
	AND V.Codice <> U.Versione
ORDER BY A.Ragione_sociale;

3. Mostrare:
- per ogni commerciale, quante attività ha svolto e verso quanti contatti distinti
- per ogni consulente, quante consulenze ha svolto e verso quanti contatti distinti
specificando il tipo di azione svolta (attività/consulenza) ed escludendo gli impiegati che al momento non lavorano più presso la società.

SELECT I.Codice, I.Cognome, I.Nome, 'Attività' Tipo, COUNT(A.Codice) Totale, COUNT(DISTINCT(A.Contatto)) Contatti_univoci
FROM Commerciale C
INNER JOIN Impiegato I ON I.Codice = C.Impiegato
INNER JOIN Attivita A ON A.Commerciale = C.Impiegato
WHERE I.Data_fine_rapporto IS NULL OR I.Data_fine_rapporto > NOW()
GROUP BY I.Codice
UNION
SELECT I.Codice, I.Cognome, I.Nome, 'Consulenza' Tipo, COUNT(CO.Contatto) Totale, COUNT(DISTINCT(CO.Contatto)) Contatti_univoci
FROM Consulente C
INNER JOIN Impiegato I ON I.Codice = C.Impiegato
INNER JOIN Consulenza CO ON CO.Consulente = C.Impiegato
WHERE (I.Data_fine_rapporto IS NULL OR I.Data_fine_rapporto > NOW())
	AND CO.Data_effettiva IS NOT NULL
GROUP BY I.Codice;

4. Mostrare l'elenco delle aziende e relative licenze attualmente attive, dove il canone di licenza è inferiore al 90% di quello standard, assieme al codice, cognome e nome del commerciale che ha seguito la trattativa, ordinando i risultati in base al codice impiegato.

DROP VIEW IF EXISTS Licenze_scontate CASCADE;
CREATE VIEW Licenze_scontate(Licenza, Canone, Canone_standard)
AS (
	SELECT L.Codice_contratto, L.Canone, P.Canone_standard
	FROM Licenza L
	INNER JOIN Versione V ON V.Codice = L.Versione
	INNER JOIN Prodotto P ON P.Nome = V.Prodotto
	WHERE (L.Data_disdetta IS NULL OR L.Data_disdetta > NOW())
		AND L.Canone < P.Canone_standard
);

SELECT A.Ragione_sociale, L.Codice_contratto, L.Canone, I.Codice, I.Cognome, I.Nome
FROM Licenza L
INNER JOIN Azienda A ON L.Azienda = A.Partita_IVA
INNER JOIN Trattativa T ON T.Attivita = L.Trattativa
INNER JOIN Commerciale C ON C.Impiegato = T.Commerciale
INNER JOIN Impiegato I ON I.Codice = C.Impiegato
WHERE L.Codice_contratto IN (
	SELECT Licenza
	FROM Licenze_scontate
	WHERE Canone_standard - Canone > (Canone_standard * 10 / 100)
)
ORDER BY I.Codice;

5. Mostrare la lista dei contatti (e relative aziende) che hanno espresso interesse nel mese di agosto 2021 per dei prodotti per i quali la loro azienda non ha attualmente alcuna licenza attiva, assieme al nome del prodotto in questione e se presente il codice del commerciale di riferimento del contatto, escludendo i contatti i cui dati non possono essere trattati per motivi di privacy e ordinando i risultati per ragione sociale.

DROP VIEW IF EXISTS Licenze_attive CASCADE;
CREATE VIEW Licenze_attive(Licenza, Azienda, Prodotto)
AS (
	SELECT L.Codice_contratto, L.Azienda, V.Prodotto
	FROM Licenza L
	INNER JOIN Versione V ON V.Codice = L.Versione
	WHERE L.Data_disdetta IS NULL OR L.Data_disdetta > NOW()
);

SELECT C.Codice Contatto, C.Cognome, C.Nome, A.Ragione_sociale, I.Prodotto, COALESCE(C.Commerciale, 'Nessuno') Commerciale
FROM Interessamento I
INNER JOIN Contatto C ON C.Codice = I.Contatto
INNER JOIN Azienda A ON A.Partita_IVA = C.Azienda
LEFT JOIN Licenze_Attive LA ON LA.Azienda = A.Partita_IVA
	AND LA.Prodotto = I.Prodotto
WHERE LA.Licenza IS NULL
	AND I.Data >= '2021-08-01' AND I.Data <= '2021-08-31'
	AND C.Data_scadenza_consenso_trattamento_dati >= NOW()
ORDER BY A.Ragione_sociale;

6. Mostrare il numero di trattative avviate per ogni tipo di attività, ordinando i risultati dal tipo di attività più efficiente al meno efficiente.

SELECT A.Tipo Tipo_attivita, COUNT(A.Codice) Trattative_avviate
FROM Attivita A
WHERE A.Codice IN (
	SELECT Attivita
	FROM Trattativa
)
GROUP BY A.Tipo
ORDER BY COUNT(A.Codice) DESC
*/