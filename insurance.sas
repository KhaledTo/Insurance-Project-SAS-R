						/*****************************
							Projet assurances belges
						******************************/

/*Nous utilisons la macro instruction let pour affecter à la variable chemin 
une chaine de caractere correspondant au chemin de notre librairie*/
*Mettre le chemin de votre lib ici ;
%LET chemin = C:\Users\admin\Desktop\STA115;
LIBNAME STA115 "&chemin";

*Le chemin du fichier (on concatene le chemin du projet et celui du chemin relatif);
%LET chemin_fichier = "&chemin.\PROJET\assurance_belges_2013_2014.txt";

*%LET chemin_projet = "";
*On concatene les deux chemins;
*%LET chemin_fichier = %UNQUOTE(&chemin&chemin_projet);

*Afficher la valeur de la macro variable chemin_fichier ;
%PUT &chemin_fichier;


/*****************************
   1.1 Import les données
******************************/


%MACRO import_data(chemin); 
  /*Nous allons importer le fichier qui sera converti en une table SAS 
	Pour cela nous utilisons une etape data	*/
	DATA STA115.assurance_belges;
		/*8 caracteres : taille par defaut sous SAS */
		INFILE &chemin_fichier FIRSTOBS=2 DLM='09'x;
		
	    INPUT ID SINISTRALITE $  CODE_USAGE $ AGE $ SEXE $ CODE_LANGUE $ CODE_POSTAL $ BON_MAL_RC $ BON_MAL_N_MOINS1 $ 
	    PUISS_VEHIC : $10. DATE_EFFET : $10. ANNEE_VEHIC : $9.  PRIMES_RC $;
		
	RUN; 

%MEND import_data;

*Appel de ma macro;
%import_data(chemin_fichier);

*Supprimer la variable;
*%SYMDEL chemin;
*%SYMDEL chemin_projet;
*%SYMDEL chemin_fichier;

/************************************************************
   1.2 Statistiques univariées et représentations graphiques 
*************************************************************/

OPTIONS ORIENTATION = LANDSCAPE;
ODS PDF FILE = "&chemin.\PROJET\assur_freq.pdf";
/*Freq : vue d'ensemble des données*/
PROC FREQ data = STA115.assurance_belges (drop=ID);
RUN;
ODS	PDF CLOSE;

ODS graphics on;
PROC FREQ data = STA115.assurance_belges (drop=ID);
	tables _ALL_ / plots = freqplot;
RUN;
ODS	graphics off;

/*On voit que pour certaines variables certaines modalités sont sur représentées (et donc d'autres sous représentées
 comme pour ;
--> utiliser proc FORMAT pour regrouper les variables 
Les frequences nous permettent d'associer à chacune des modalités les modalités demandées dans l'exercice ; par exemple 

Cf ACM effectifs modalités 
EXPLIQUER AVANTAGE FORMAT par rapport recoder dataset : flexibilité : changer de FORMAT autant de fois que necessaire sans avoir 
à dupliquer les dataset 
*/

*Age de l'assuré  1890 - 1949 (1 à 4)/ 1950 - 1973 (5 à 8) / inconnu  (9); 
 
/**********************************************************************
   1.3 Regrouper les modalités peu fréquentes en vue de préparer l’ACM
***********************************************************************/
/*Voir cours SAS 4*/
PROC FORMAT lib = STA115 ;
	  value  $AGE
	 'AGE=1','AGE=2', 'AGE=3', 'AGE=4' = '1890-1949'
	 'AGE=5','AGE=6', 'AGE=7', 'AGE=8' = '1950-73'
	 'AGE=9' = 'Naissance inconnue';
 RUN;

*Code postal souscripteur 	: Bruxelles (1) et autres;
PROC FORMAT lib = STA115 ;
	  value  $CODE_POSTAL
	 'CPOST=1'= 'Bruxelles'
	  other = 'Autres CP';
 RUN;
* Bonus Malus :  B-MC1 (1) et autres  ;
PROC FORMAT lib = STA115 ;
	  value  $BON_MAL_RC
	 'BM=1'= 'B-MC'
	  other = 'Autres B-MC';
 RUN;
* Bonus Malus N -1 :  B-M1_1 (1) et autres ;
PROC FORMAT lib = STA115 ;
	  value  $BON_MAL_RC_N_MOINS_UN
	 'BM_1=1'= 'B-M1(-1)'
	  other = 'Autres B-M(-1)';
 RUN;
*Date effet police : la date effet police est déjà regroupée en deux modalités : on se contente donc de changer le nom de
la modalité  : <86 Police correspond à 	DPOLI2M=1 et autres à DPOLI2M=2;
PROC FORMAT lib = STA115 ;
	  value  $DATE_EFFET
	 'DPOLI2M=1'= '<86'
	  other = '>86';
 RUN;
*Puiss vehicule  10 - 39 : 1,2 et 3 et 40 - 349 : autres;
 PROC FORMAT lib = STA115 ;
	  value $PUISS_VEHIC
	 'PUIS12M=1', 'PUIS12M=2', 'PUIS12M=3'= '10-39 Puis'
	  other = '40-349 Puis';
 RUN;

*Annee de construction  33-89 et 90-91 idem déjà encodé; 
  PROC FORMAT lib = STA115 ;
	  value $ANNEE_VEHIC
	 'DCONS2M=1'= '33-89 DCOS'
	  other = '90-91 DCOS';
 RUN;


/*Pour utiliser des formats qui se trouvent ailleurs que dans la lib WORK (voir cours 4)*/
option fmtsearch=(STA115);

 *Afficher les formats crées;
PROC FORMAT lib=STA115 fmtlib;
RUN;

/**********************************************************************************************************
   1.4 Lien entre les variables explicatives transformées et la variable à expliquer ; la variable SINISTRE
***********************************************************************************************************/
ODS OUTPUT ChiSq = Chi2;

PROC FREQ  DATA = STA115.Assurance_belges (drop=ID );
	TABLES SINISTRALITE *(BON_MAL_RC PRIMES_RC AGE DATE_EFFET CODE_POSTAL ANNEE_VEHIC CODE_USAGE PUISS_VEHIC
	SEXE CODE_LANGUE) / CHISQ ;
RUN;

/*Chi2 */
DATA Chi2 (keep = Table Value);
	SET Chi2;
	WHERE Statistic like 'Cramer%';
	*'Chi-Square';
RUN;

PROC SORT DATA = Chi2;
	BY DESCENDING Value;
RUN;

PROC PRINT DATA = Chi2;
RUN;

/**********************************************************************
   1.5 Construction du tableau disjonctif
***********************************************************************/
PROC CORRESP DATA=STA115.Assurance_belges DROP=ID BINARY outf=STA115.freqs noprint;
	TABLES SINISTRALITE CODE_USAGE SEXE CODE_LANGUE AGE CODE_POSTAL 
	DATE_EFFET BON_MAL_N_MOINS1   PUISS_VEHIC ANNEE_VEHIC PRIMES_RC ;
	FORMAT AGE $AGE. CODE_POSTAL $CODE_POSTAL. BON_MAL_N_MOINS1 $BON_MAL_RC_N_MOINS_UN.
	PUISS_VEHIC $PUISS_VEHIC. DATE_EFFET $DATE_EFFET. ANNEE_VEHIC $ANNEE_VEHIC.;
RUN;

PROC TRANSPOSE data=STA115.freqs out = STA115.rfreqs (rename=(col1=I_SINIS1
col2=I_SINIS2 col3=I_CUSAG1 col4=I_CUSAG2 col5=I_SEXE1 col6=I_SEXE2 col7=I_SEXE3
col8=I_CLANG1 col9=I_CLANG2 col10=I_AGE3M1 col11=I_AGE3M2 col12=I_AGE3M3
/*Attention ordre inverse pour CPOST : ordre alphabetique 'autres' est avant 'Bruxelles'
idem pour BMN-1*/
col13=I_CPOST2 col14=I_CPOST1 col15=I_DPOLI1 col16=I_DPOLI2 col17=I_BM_12 col18=I_BM_11
col19=I_PUIS1 col20=I_PUIS2	col21=I_DCONS1 col22=I_DCONS2 col23=I_PRIM1 col24=I_PRIM2 col25=I_PRIM3
));
	WHERE _type_ eq 'OBSERVED';
	var count;
	by row;
run;


/**********************************************************************
   1.6 ACM
***********************************************************************/
PROC CORRESP DATA= STA115.rfreqs DIMENS=13 OUT=STA115.ACM_coordonnees NOROW=print;
	VAR I_SINIS1 I_SINIS2 I_CUSAG1 I_CUSAG2 I_SEXE1 I_SEXE2 I_SEXE3
	I_CLANG1 I_CLANG2 I_AGE3M1 I_AGE3M2 I_AGE3M3
	I_CPOST2 I_CPOST1 I_DPOLI1 I_DPOLI2 I_BM_12 I_BM_11
	I_PUIS1 I_PUIS2	I_DCONS1 I_DCONS2 I_PRIM1 I_PRIM2 I_PRIM3;
	SUPPLEMENTARY I_SINIS1 I_SINIS2;
	ID ROW;
RUN;

%LET fichier = "&chemin.\PROJET\ACM_coordonnees.csv";

*Exporter ;
PROC EXPORT DATA = 	STA115.Acm_coordonnees(keep=Dim1-Dim13) OUTFILE=&fichier 
	DBMS=csv REPLACE;
RUN;


/**********************************************************************
   1.7 Représentation du premier plan factoriel
***********************************************************************/

DATA STA115.coord;
	SET STA115.Acm_coordonnees;
	ID = INPUT(Row, 8.);
	WHERE _type_='OBS';
	KEEP  ID Dim1 Dim2;
RUN;

DATA STA115.Assurance_belges_SINISTRE ;
	SET STA115.Assurance_belges;
	KEEP ID SINISTRALITE;
RUN;

/*Attention les ID ne matchent pas : donc à ne pas utiliser dans le MERGE*/
DATA STA115.graph_ACM;
	MERGE STA115.Assurance_belges_SINISTRE STA115.coord;
RUN;


GOPTIONS RESET=all;
SYMBOL1 v=CIRCLE c=BLUE;
SYMBOL2 v=DOT c=RED;
PROC GPLOT DATA=STA115.graph_ACM;
	WHERE _type_='OBS';
	PLOT Dim2*Dim1 = SINISTRALITE;
RUN;
QUIT;

/**********************************************************************
   1.8 Discrimination des individus par le premier axe factoriel
***********************************************************************/
DATA STA115.CLASSIFICATION_SINISTRE;
	SET STA115.graph_ACM;
	IF Dim1 > 0 THEN SIN_PREDIT='SINIST=2';
	ELSE SIN_PREDIT='SINIST=1';
RUN;

/**********************************************************************
   1.9 Pourcentage d’assurés mal classés
***********************************************************************/
PROC FREQ data=STA115.CLASSIFICATION_SINISTRE;
	TABLES SIN_PREDIT*SINISTRALITE / out=qual nocol norow;
	title "Matrice de confusion";
RUN;

