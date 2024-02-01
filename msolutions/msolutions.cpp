#include <iostream>

#include <cstdio>
#include <fstream>
#include "dependencies/include/libpq-fe.h"

#define PG_HOST "127.0.0.1"
#define PG_USER "postgres"
#define PG_DB "msolutions" // database
#define PG_PASS "1234" // password
#define PG_PORT 5432 // porta

using namespace std;

// funzione di controllo dei risultati
void checkResults (PGresult* res, const PGconn* conn) {
	
	if (PQresultStatus(res) != PGRES_TUPLES_OK) {
		
		cout << "Risultati inconsistenti: " << PQerrorMessage(conn) << endl;
		
		PQclear(res);
		system("pause");
		exit(1) ;
	}
	
}

// funzione di stampa dei risultati
void printResults (PGresult* res) {
	
	int rows = PQntuples(res) ;
	int columns = PQnfields(res) ;
	
	// intestazioni
	for (int i = 0; i < columns; ++i) {
		cout << PQfname(res, i) << " | "; //"\t\t";
	}
	cout << endl;
	
	// tuple e valori
	for (int i = 0; i < rows; ++i) {
			for (int j = 0; j < columns; ++j) {
				cout << PQgetvalue (res, i, j ) << " | "; //"\t\t";
		}
		cout << endl;
	}
	
	cout << endl << endl;
}

int main (int argc, char** argv) {

	// stringa di connessione al database
	char conninfo[250];
	sprintf(conninfo, "user=%s password=%s dbname=%s hostaddr=%s port=%d",
							PG_USER, PG_PASS, PG_DB, PG_HOST, PG_PORT );

	// puntatore
	PGconn* conn = PQconnectdb(conninfo);
	
	// se la connessione non e' avvenuta correttamente, termino l'esecuzione del programma	
	if (PQstatus(conn) != CONNECTION_OK) {
		
		cout << "Errore di connessione: " << PQerrorMessage(conn) << endl;
		PQfinish(conn);
		
		system("pause");
		exit(1);
	}
	else {
		
		cout << "Connessione avvenuta correttamente: preparazione database in corso." << endl << endl;
		
		// variabile contenente la query sql
		PGresult* res;
		
		// eliminazione delle viste già esistenti
		res = PQexec(conn, "DROP VIEW IF EXISTS Ultime_versioni CASCADE; DROP VIEW IF EXISTS Licenze_scontate CASCADE; DROP VIEW IF EXISTS Licenze_attive CASCADE;");
		PQclear(res);
		
		cout << endl;
		
		// query 1
		cout << "Mostrare, per tutti i prodotti, gli incassi totali del mese di agosto 2021, fare una stima degli incassi per settembre 2021 in base alle licenze attive e ai rispettivi canoni, ordinando i risultati per tipo prodotto e successivamente dall'incasso previsto piu' alto a quello piu' basso." << endl << endl;
		
		res = PQexec(conn, "SELECT P.Nome, P.Tipo, COALESCE(TI.Totale_incassato_agosto, 0) Totale_incassato_agosto, COALESCE(IP.Incassi_previsti_settembre, 0) Incassi_previsti_settembre FROM Prodotto P LEFT JOIN ( 	SELECT V.Prodotto, SUM(P.Importo) Totale_incassato_agosto FROM Pagamento P INNER JOIN Licenza L ON L.Codice_contratto = P.Licenza INNER JOIN Versione V ON V.Codice = L.Versione WHERE P.Data >= '2021-08-01' AND P.Data <= '2021-08-31' GROUP BY V.Prodotto ) TI ON TI.Prodotto = P.Nome LEFT JOIN ( SELECT V.Prodotto, SUM(L.Canone) Incassi_previsti_settembre FROM Licenza L INNER JOIN Versione V ON V.Codice = L.Versione WHERE L.Data_disdetta IS NULL OR L.Data_disdetta >= '2021-09-01' GROUP BY V.Prodotto ) IP ON IP.Prodotto = P.Nome ORDER BY P.Tipo, COALESCE(IP.Incassi_previsti_settembre, 0) DESC;");
		
		checkResults(res, conn);
		printResults(res);
		PQclear(res);
		
		// query 2
		cout << "Mostrare l'elenco delle licenze attive ma non ancora aggiornate all'ultima versione del prodotto disponibile, assieme alla ragione sociale dell'azienda licenziataria, nome del software in questione, versione attuale e versione disponibile per l'aggiornamento, ordinando i risultati in base alla ragione sociale." << endl << endl;
		
		res = PQexec(conn, "CREATE VIEW Ultime_versioni(Prodotto, Versione) AS ( SELECT V.Prodotto, V.Codice FROM Versione V INNER JOIN ( SELECT Prodotto, MAX(Data_rilascio) Data_rilascio FROM Versione GROUP BY Prodotto) U ON U.Prodotto = V.Prodotto AND U.Data_rilascio = V.Data_rilascio ); SELECT L.Codice_contratto, A.Ragione_sociale, V.Prodotto, V.Codice Versione_attuale, U.Versione Versione_disponibile FROM Licenza L INNER JOIN Azienda A ON A.Partita_IVA = L.Azienda INNER JOIN Versione V ON V.Codice = L.Versione INNER JOIN Ultime_versioni U ON U.Prodotto = V.Prodotto WHERE (L.Data_disdetta IS NULL OR L.Data_disdetta > NOW()) AND V.Codice <> U.Versione ORDER BY A.Ragione_sociale;");
		
		checkResults(res, conn);
		printResults(res);
		PQclear(res);
		
		// query 3
		cout << "Mostrare:" << endl << "- per ogni commerciale, quante attivita' ha svolto e verso quanti contatti distinti" << endl << "- per ogni consulente, quante consulenze ha svolto e verso quanti contatti distinti" << endl << "specificando il tipo di azione svolta (attivita'/consulenza) ed escludendo gli impiegati che al momento non lavorano piu' presso la societa'." << endl << endl;
		
		res = PQexec(conn, "SELECT I.Codice, I.Cognome, I.Nome, 'Attivita' Tipo, COUNT(A.Codice) Totale, COUNT(DISTINCT(A.Contatto)) Contatti_univoci FROM Commerciale C INNER JOIN Impiegato I ON I.Codice = C.Impiegato INNER JOIN Attivita A ON A.Commerciale = C.Impiegato WHERE I.Data_fine_rapporto IS NULL OR I.Data_fine_rapporto > NOW() GROUP BY I.Codice UNION SELECT I.Codice, I.Cognome, I.Nome, 'Consulenza' Tipo, COUNT(CO.Contatto) Totale, COUNT(DISTINCT(CO.Contatto)) Contatti_univoci FROM Consulente C INNER JOIN Impiegato I ON I.Codice = C.Impiegato INNER JOIN Consulenza CO ON CO.Consulente = C.Impiegato WHERE (I.Data_fine_rapporto IS NULL OR I.Data_fine_rapporto > NOW()) AND CO.Data_effettiva IS NOT NULL GROUP BY I.Codice;");
		
		checkResults(res, conn);
		printResults(res);
		PQclear(res);
		
		// query 4
		cout << "Mostrare l'elenco delle aziende e relative licenze attualmente attive, dove il canone di licenza e' inferiore al 90% di quello standard, assieme al codice, cognome e nome del commerciale che ha seguito la trattativa, ordinando i risultati in base al codice impiegato." << endl << endl;
		
		res = PQexec(conn, "CREATE VIEW Licenze_scontate(Licenza, Canone, Canone_standard) AS ( SELECT L.Codice_contratto, L.Canone, P.Canone_standard 	FROM Licenza L 	INNER JOIN Versione V ON V.Codice = L.Versione 	INNER JOIN Prodotto P ON P.Nome = V.Prodotto WHERE (L.Data_disdetta IS NULL OR L.Data_disdetta > NOW()) AND L.Canone < P.Canone_standard );  SELECT A.Ragione_sociale, L.Codice_contratto, L.Canone, I.Codice, I.Cognome, I.Nome FROM Licenza L INNER JOIN Azienda A ON L.Azienda = A.Partita_IVA INNER JOIN Trattativa T ON T.Attivita = L.Trattativa INNER JOIN Commerciale C ON C.Impiegato = T.Commerciale INNER JOIN Impiegato I ON I.Codice = C.Impiegato WHERE L.Codice_contratto IN ( 	SELECT Licenza 	FROM Licenze_scontate WHERE Canone_standard - Canone > (Canone_standard * 10 / 100) ) ORDER BY I.Codice;");
		
		checkResults(res, conn);
		printResults(res);
		PQclear(res);
		
		// query 5
		cout << "Mostrare la lista dei contatti (e relative aziende) che hanno espresso interesse nel mese di agosto 2021 per dei prodotti per i quali la loro azienda non ha attualmente alcuna licenza attiva, assieme al nome del prodotto in questione e se presente il codice del commerciale di riferimento del contatto, escludendo i contatti i cui dati non possono essere trattati per motivi di privacy e ordinando i risultati per ragione sociale." << endl << endl;
		
		res = PQexec(conn, "CREATE VIEW Licenze_attive(Licenza, Azienda, Prodotto) AS ( SELECT L.Codice_contratto, L.Azienda, V.Prodotto FROM Licenza L INNER JOIN Versione V ON V.Codice = L.Versione WHERE L.Data_disdetta IS NULL OR L.Data_disdetta > NOW()); SELECT C.Codice Contatto, C.Cognome, C.Nome, A.Ragione_sociale, I.Prodotto, COALESCE(C.Commerciale, 'Nessuno') Commerciale FROM Interessamento I INNER JOIN Contatto C ON C.Codice = I.Contatto INNER JOIN Azienda A ON A.Partita_IVA = C.Azienda LEFT JOIN Licenze_Attive LA ON LA.Azienda = A.Partita_IVA AND LA.Prodotto = I.Prodotto WHERE LA.Licenza IS NULL AND I.Data >= '2021-08-01' AND I.Data <= '2021-08-31' AND C.Data_scadenza_consenso_trattamento_dati >= NOW() ORDER BY A.Ragione_sociale;");
		
		// query 6
		cout << "Mostrare il numero di trattative avviate per ogni tipo di attivita', ordinando i risultati dal tipo di attivita' piu' efficiente al meno efficiente." << endl << endl;
		
		res = PQexec(conn, "SELECT A.Tipo Tipo_attivita, COUNT(A.Codice) Trattative_avviate FROM Attivita A WHERE A.Codice IN (	SELECT Attivita FROM Trattativa) GROUP BY A.Tipo ORDER BY COUNT(A.Codice) DESC");
		
		checkResults(res, conn);
		printResults(res);
		PQclear(res);
		
		PQfinish(conn);
		
		system("pause");
		return 0;
	}
	
}
