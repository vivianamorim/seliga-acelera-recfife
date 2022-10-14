

	**
	**
	*EMPREL - FLUXO DE ESTUDANTES NAS TURMAS REGULARES E DE ACELERAÇÃO
	* _____________________________________________________________________________________________________________________________________________________________ *
		
		*
		*
		*ESTUDANTES INICIAIS E FINAIS
		*
		* __________________________________________________________________________________________________________________________________________________________ *
		/*
		{	
			**
			foreach 	etapa in INICIAIS FINAIS {
				forvalues 	year = 2008(1)2018 {
					import 			excel  using "$dtraw/EMPREL/ESTUDANTES_`etapa'_`year'.xlsx", firstrow allstring clear
					tempfile 		`etapa'`year'
					save 	   	   ``etapa'`year''
				}
			}
			
			**
			clear
				forvalues 	year = 2008(1)2018 {
					append 	using `INICIAIS`year''
					append 	using `FINAIS`year''
				}
				
			**
			rename 		(ANOLETIVO 	RPA INEP 		ANOENSINO TURMA TURNO  MATRICULA NOMEDOALUNO  SEXO   SITUAÇÃO NOMEDAMÃE) ///
						(year 	  	rpa codschool 	grade 	  turma period cd_mat 	 name_student gender status   nm_mae   )
					
			**
			drop 		CÓD UNIDADEDEENSINO MODALIDADE
			
			**
			drop	 	if year == ""
			destring,	replace
			
			**
			duplicates 	tag year cd_mat name_student, gen(tag) 					//duplicados, mesmo aluno aparecendo duas vezes em um mesmo ano. 
			sort 		name_student status
			br 			if tag == 1 											//temos alguns exemplos de duplicação que não fazem sentido: retido em uma escola e aprovado em outra. 
			
			**
			local 		nomes = `" "MIRELA VITORIA DE LIMA SOARES" "IGOR LEONARDO OZORIO ALVES" "GABRIEL HENRIQUE MARINHO SILVA" "GRACIELE MARIA DA SILVA" "DAYANA MATIAS DE LIMA" "RAISSA MARIELLE DOS SANTOS RAMOS" "VICTOR MANUEL ANASTACIO GOMES" "EMANOEL DE SOUZA GADELHA" "KAWAN KAYKE BALTAR DE SOUZA" "THAYSA VITORIA DA SILVA NEVES" "'
			foreach		word of local nomes {
				drop 	if tag == 1 & name_student == "`word'"					//alunos que apresentam o mesmo status em escolas diferentes ou que apresentam um status de retido ou outro como aprovado, ou outras mudanças que não fazem sentido
			}
			
			**
			drop 		if tag == 1 & status   == "REMANEJADO" 					//nesse caso, o status do aluno aparece na escola para a qual ele foi remanejado
			drop 		if tag == 1 & status   == "TR DUR ANO P/REDE"  | status == "TR DUR ANO S/INFO" 
			drop 		   tag	
			
			**
			compress
			save "$dtinter/Estudantes das turmas regulares.dta", replace
		}
		*/
		
		
		*
		*
		*ESTUDANTES DAS TURMAS DE ACELERAÇÃO
		*
		* __________________________________________________________________________________________________________________________________________________________ *
		{
		/*
			**
			forvalues 	year = 2010(1)2018 {
				import 			excel  using "$dtraw/EMPREL/Estudantes_Correção_Fluxo_`year'.xlsx", firstrow allstring clear
				tempfile 		`year'
				save 	  	   ``year''
			}
			
			**
			clear
			forvalues 	year = 2010(1)2018 {
				append	 using ``year''
			}
			
			**
			rename 		(ANOLETIVO 	RPA INEP 	  ANOENSINO	 	MATRICULA 	NOMEDOALUNO  	 SEXO   SITUAÇÃO ANOREFERÊNCIA MODALIDADEREF NOMEDAMÃE) ///
						(year 	   	rpa codschool type_program  cd_mat 		name_student 	 gender status   grade         modalidade    nm_mae   ) 
				   
			**	   
			replace 	modalidade  		= 	trim(modalidade)
			keep 		if type_program 	== 	"ACELERA" | type_program == "SE LIGA"
			keep 		if modalidade 		== 	"ENSINO FUNDAMENTAL"
			
			**
			drop 		CÓD UNIDADEDEENSINO MODALIDADE ANOLETIVO_1-DATAMOV modalidade
			destring,	replace
			
			**
			duplicates 	tag year cd_mat name_student, gen(tag) 
			br 		 	if tag == 1 								//there are duplicates and they do not seem reasonable (same name but different classrooms?)
			
			**
			local 		nomes = `" "GABRIEL LEANDRO DA SILVA" "JOAO VICTOR RODRIGUES DA SILVA" "'
			foreach 	word of local nomes {
				drop 	if tag == 1 & name_student == "`word'"								 
			}
				
			**
			replace 	   tag = 2 if tag[_n-1] == 1 & name_student[_n] == name_student[_n-1] 		//
			drop 		if tag == 2
			drop 		   tag
			
			**
			gen 	turma = "20000"									if type_program == "SE LIGA" //As turmas do se liga e acelera nao apresentam codigo de identificacao, nem periodo (manha, tarde ou integral)
			replace turma = "30000" 								if type_program == "ACELERA"
						
			**
			compress
			save "$dtinter/Estudantes das turmas de correção de fluxo.dta", replace
			*/
		}	
		
		
		
		*
		*
		*ESTUDANTES POR ANO -> SLA + REGULAR
		*
		* __________________________________________________________________________________________________________________________________________________________ *
			
		/*	
			*Merging Regular + SLA
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				use 	  		"$dtinter/Estudantes das turmas regulares.dta", clear
				merge 			1:1 year cd_mat using "$dtinter/Estudantes das turmas de correção de fluxo.dta" // merge == 3 its error. Students that are enrolled in either ACELERA or SE LIGA but their names are in the list of regular students
				keep 			if _merge == 3 //ERROR*
				keep 			cd_mat year
				tempfile 		 exclusao
				save    		`exclusao'
			}
			
			
			*Appending regular students + SE LIGA/Acelera students*
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				use   		"$dtinter/Estudantes das turmas regulares.dta", clear
				merge 		m:1 year cd_mat using `exclusao', keep(1) nogen
				gen			type_program = "REGULAR" 
				append  	using "$dtinter/Estudantes das turmas de correção de fluxo.dta"		
				drop if codschool == .
			}	
				
			
				
			*Horario, tipo de programa e genero
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				**
				replace 	gender    		= "1" if gender   			== "FEM"
				replace 	gender    		= "0" if gender   			== "MASC"
				
				**
				replace 	period    		= "1" if period    			== "INTEGRAL"
				replace 	period    		= "2" if period   			== "MANHÃ"
				replace 	period    		= "3" if period    			== "TARDE"
				replace 	period    		= "4" if period   	  		== "NOITE"			
				replace 	period   		= "5" if period       		== "INTERMEDIÁRIO"		
				
				**
				replace 	type_program    = "1" if type_program 		== "REGULAR"
				replace 	type_program    = "2" if type_program 		== "SE LIGA"
				replace 	type_program    = "3" if type_program 		== "ACELERA"
				
				**
				gen 		dt_nasc    = date(DATANASC, "MDY")
				format  	dt_nasc %td
			}	
					
					
			*Status
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				local desistente   `" "DESISTENTE" 			 "DESIST REN C/ TRANSF"  		 "DESIST/DEIXOU FREQUE"  "DESISTENTE RENOVADO"  "NUNCA COMPARECEU"   "'
				local repetente    `" "REPROV P/  FALTA"  	 "RETIDO" "RETIDO E TR P/ REDE"  "RETIDO POR FALTA"      "RETIDO POR IDADE" 	"RT FALTA TR P/REDE" "'
				local transferido  `" "TR DUR ANO FORA REDE" "TR DUR ANO P/REDE"    		 "TR DUR ANO P/REDE" 	 "TR FIM ANO ESTADO" 	"REMANEJADO" "TR FIM ANO F/REDE" "AP TR FIM ANO S/INFO" "TR FIM ANO P/REDE" "TR FIM ANO S/INFO"  "'
				
				**
				*Aprovado
				replace status		= "1" if status == "APROVADO" 
				
				**
				*Desistente
				foreach word of local desistente {
					replace status 	= "3" if status == "`word'"
				}
				
				**
				*Reprovado
				foreach word of local repetente {
					replace status  = "2" if status == "`word'"
				}
				
				**
				*Transferido
				foreach word of local transferido {
					replace status  = "0" if status == "`word'"
				}
				
				**
				replace status = "4" if status == "FALECIDO"
				replace status = "5" if status == "RENV S/SIT FINAL DEF" | status == "RF TR FIM ANO P/REDE" | status == "RF TR FIM ANO S/INFO" | status == "FREQÜENTE" | status == "RECLASSIFICADO"
				
				**
				destring, replace			
			}
			
			
			*Grade
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				replace  	grade   = "1"   if grade == "CICLO 1 ANO 1" | grade == "1º ANO"
				replace  	grade   = "2"   if grade == "CICLO 1 ANO 2" | grade == "2º ANO"
				replace  	grade   = "3"   if grade == "CICLO 1 ANO 3" | grade == "3º ANO"
				replace  	grade   = "4"   if grade == "CICLO 2 ANO 1" | grade == "4º ANO"
				replace  	grade   = "5"   if grade == "CICLO 2 ANO 2" | grade == "5º ANO"
				replace  	grade   = "6"   if grade == "CICLO 3 ANO 1" | grade == "6º ANO"
				replace  	grade   = "7"   if grade == "CICLO 3 ANO 2" | grade == "7º ANO"
				replace  	grade   = "8"   if grade == "CICLO 4 ANO 1" | grade == "8º ANO"
				replace  	grade   = "9"   if grade == "CICLO 4 ANO 2" | grade == "9º ANO"
				destring 	grade, replace
			}	
				
			
			*Labels	
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{	
				label define     grade 				 1 "1{sup:st} grade" 2 "2{sup:nd} grade" 3 "3{sup:rd} grade" 4 "4{sup:th} grade" 5 "5{sup:th} grade" 6 "6{sup:th} grade" 7 "7{sup:th} grade" 8 "8{sup:th} grade" 9 "9{sup:th} grade"
				label val 		 grade grade
				label define 	 type_program 		 1 "Regular"         2 "Se liga"         3 "Acelera"
				label val 		 type_program type_program
				label define 	 period			     1 "Integral" 		 2 "Morning" 	     3 "Afternoon"       4 "Night"           5 "Intermediate"
				label val 		 period  period
				label define 	 gender 			 1 "Female"    	     0 "Male"
				label val    	 gender gender 
				label define     status 			 0 "Transfered"      1 "Approved"        2 "Repeated"        3 "Dropped out"     4 "Died"            5 "No status"
				label val        status status
			}	
			
					
			*Correcting student's names and the name of their mothers
			*----------------------------------------------------------------------------------------------------------------------------------------------------- *			
			{  
				replace name_student 	= trim(name_student)
				replace nm_mae			= trim(nm_mae)
				gen 	string 			= string(dt_nasc)
				gen 	size_name 		= length(name_student)
				count if codschool == .
				count if name_student == ""
				
				sort	 	cd_mat year
				bys 	 	cd_mat: egen nascimento = mode(dt_nasc)																		//nesse caso, vamos considerar como a data de nascimento, a data que mais se repete
				replace  	dt_nasc =    nascimento if !missing(nascimento)
				drop 		nascimento
				
				
				//por codigo da matricula, quais os alunos aparecem no painel com distintos nomes de maes?
				*---------------------------------------------------------------------->>>>
				{
				bys 	cd_mat: egen mae = mode(nm_mae)
				sort    cd_mat year
				br 		cd_mat year name_student dt_nasc grade codschool nm_mae mae if mae != nm_mae
				br      cd_mat year name_student dt_nasc grade codschool nm_mae mae if inlist(cd_mat,7053681,9007105,11449098,15724166)
				replace nm_mae = mae if mae != nm_mae & !missing(mae) 
				drop 	mae
				}
				
				
				//estudantes com mesmo nome, data de nascimento e escola, mas com erros de grafia entre os anos no nome da mae
				//name_student, dt_nasc codschool
				*---------------------------------------------------------------------->>>>
				{
				cap program drop atencao
				program define   atencao
				cap noi drop mae atencao max_atencao
				bys 	name_student dt_nasc codschool: egen mae = mode(nm_mae)
				gen 	atencao = 1 if mae != nm_mae & !missing(dt_nasc)
				bys 	name_student dt_nasc codschool: egen max_atencao = max(atencao)
				sort 	name_student dt_nasc codschool year grade 
				br 		cd_mat name_student dt_nasc codschool year grade mae nm_mae if max_atencao == 1		//podemos ver que sao erros de grafia. 
				end
				
				atencao
				replace nm_mae = mae if max_atencao == 1 & !missing(mae) & length(name_student) > 24       //trocando o nome da mae pela moda, somente para alunos cujo nome tenha mais de 24 caracteres para nao corrermos o risco de ter mais de um aluno com mesmo nome, mesma data de nascimento e mesma escola. 
				do 		"$dofiles\Correcting Mothers' names.do"		//para quando a moda for igual a missing e o nome do aluno tem menos de 25 caracteres, os nomes nesse do file correcting mothers' name eu verifiquei um por um
				atencao
				}
				
				
				//estudante com mesmo nome e data de nascimento, mas com erros de grafia no nome da mae
				//name_student, dt_nasc
				*---------------------------------------------------------------------->>>>
				{
				cap program drop atencao
				program define   atencao
				cap noi drop mae atencao max_atencao
				bys 	name_student dt_nasc: egen mae = mode(nm_mae)
				gen 	atencao = 1 if mae != nm_mae & !missing(dt_nasc)
				bys 	name_student dt_nasc: egen max_atencao = max(atencao)
				sort 	name_student dt_nasc year grade 
				end 
				
				atencao
				br 		year cd_mat name_student size_name dt_nasc codschool year grade mae nm_mae  if max_atencao == 1 & 				  length(name_student) > 24 & !missing(dt_nasc)
				replace nm_mae = mae 																if max_atencao == 1 & !missing(mae) & length(name_student) > 24 & !missing(dt_nasc)
				atencao
				br 		year cd_mat name_student string dt_nasc  mae nm_mae  codschool year grade 	if max_atencao == 1 & !missing(dt_nasc)
				do 		"$dofiles\Correcting Mothers' names2.do"		//for when mae == missing. 
				atencao
				order   year cd_mat name_student string dt_nasc  mae nm_mae  codschool year grade
				br 		year cd_mat name_student string dt_nasc  mae nm_mae  codschool year grade 	if max_atencao == 1 & !missing(dt_nasc)
				drop mae
				}
				
				
				//mesmo codigo de matricula mas nome do aluno diferente
				*---------------------------------------------------------------------->>>>
				{
				drop atencao max_atencao
				bys	 	cd_mat: egen aluno = mode(name_student)
				gen 	atencao = 1 if aluno != name_student
				bys 	cd_mat: egen max_atencao = max(atencao)
				sort 	cd_mat year
				br		cd_mat year name_student aluno if max_atencao == 1
				replace name_student = aluno if aluno != name_student & !missing(aluno)
				drop aluno atencao max_atencao
				}
				
				
			*Same identification code, mas erros de grafia/ no nome do estudante ou da mae
			*----------------------------------------------------------------------------------------------------------------------------------------------------- *			
				{
				
				sort cd_mat year
				count if cd_mat==cd_mat[_n-1] & name_student[_n] 	!=  name_student[_n-1]
				replace name_student ="EDVALDO FRANCISCO DE LIMA JUNIOR" if cd_mat == 11458259
				drop 	erro max_erro aluno

				count if cd_mat==cd_mat[_n-1] & nm_mae[_n] 			!=  nm_mae[_n-1]
				
				cap program drop atencao
				program define       atencao
				cap noi drop erro max_erro mae
				gen 	erro = 1 if cd_mat==cd_mat[_n-1] & nm_mae[_n] !=  nm_mae[_n-1]
				bys   	cd_mat: egen max_erro = max(erro)
				sort  	cd_mat year
				bys   	cd_mat: egen mae= mode(nm_mae)
				order 	cd_mat year grade name_student nm_mae mae dt_nasc 
				br   	cd_mat year grade name_student nm_mae mae dt_nasc if max_erro == 1
				end 
				
				atencao
				replace nm_mae = mae  if !missing(mae)
				atencao

				replace nm_mae ="ROSILENE DE FRANCISCA DOS SANTOS" if cd_mat ==6057535
				replace nm_mae ="ROSEMERE PEREIRA DE ARAUJO" if cd_mat ==11502720
				replace nm_mae ="DANIELLE SANTOS MARINHO" if cd_mat ==15006204
				replace nm_mae ="IZABELA FRANCISCA GOMES" if cd_mat ==17779413
				replace nm_mae = "CRISTIANE FERNANDES DOS SANTOS" if cd_mat == 16745949
				replace nm_mae ="CLARICE MARIA NASCIMENTO FERREIRA" if name_student =="KETHELYN NICOLLY FERREIRA DE FREITAS"& year ==2018& cd_mat ==7011172
				replace nm_mae ="FABIANA DOMINGOS PORTO DOS SANTOS" if name_student =="JOSE EDUARDO PORTO DOS SANTOS"& year ==2016& cd_mat ==12996955
				replace nm_mae ="FABIANA DOMINGOS PORTO DOS SANTOS" if name_student =="JOSE EDUARDO PORTO DOS SANTOS"& year ==2018& cd_mat ==12996955
				replace nm_mae ="MARIA DE LOURDES DA CONCEICAO" if name_student =="MARIA LUIZA DA CONCEICAO"& year ==2016& cd_mat ==15104699
				replace nm_mae ="MARIA EDINALDA ALBINO DE SOUZA" if name_student =="DRIELLY KAIANNE ALBINO DE SOUZA"& year ==2016& cd_mat ==15660605
				replace nm_mae ="AGLANIA OLIVEIRA DO NASCIMENTO" if name_student =="THALYS ALEXANDRE OLIVEIRA DO NASCIMENTO"& year ==2016& cd_mat ==15692230
				replace nm_mae ="AGLANIA OLIVEIRA DO NASCIMENTO" if name_student =="THALYS ALEXANDRE OLIVEIRA DO NASCIMENTO"& year ==2017& cd_mat ==15692230
				replace nm_mae ="AGLANIA OLIVEIRA DO NASCIMENTO" if name_student =="THALYS ALEXANDRE OLIVEIRA DO NASCIMENTO"& year ==2018& cd_mat ==15692230
				replace nm_mae ="LUCIANA BENTO DA SILVA" if name_student =="PAMELA PATRICIA BENTO DOS SANTOS"& year ==2017& cd_mat ==15724557
				replace nm_mae ="ANA CRISTINA DA SILVA" if name_student =="LEONI EVERTON DA SILVA MOURA"& year ==2017& cd_mat ==16035496
				replace nm_mae ="WILMA ROSE DAMASIO DA SILVA NUNES" if name_student =="WILLIAM GOMES DA SILVA"& year ==2017& cd_mat ==16738012
				replace nm_mae ="ROZEANE FERNANDES DE LIMA DAS MERCES" if name_student =="RAYZA VITORIA PADILHA DE LIMA"& year ==2017& cd_mat ==16759796
				replace nm_mae ="MICHELE DA CONCEICAO DUARTE DA SILVA" if name_student =="ORLANDO AYALA DUARTE DE MELO"& year ==2017& cd_mat ==16787420
				replace nm_mae ="JACILENE CARLOS DA SILA" if name_student =="DEBORA EVELIN DA SILVA NASCIMENTO"& year ==2018& cd_mat ==17054079
				replace nm_mae ="ROSINEIDE MARTIS RODRIGUES" if name_student =="LHYZANDRA RODRIGUES DE BRITO"& year ==2018& cd_mat ==17058341
				replace nm_mae ="PATRICIA MARIA PANTA NETO" if name_student =="KAYLANE PANTA NETO DE ANDRADE"& year ==2018& cd_mat ==17654092
				replace nm_mae ="LUCIANA BENTO DA SILVA" if name_student =="PAMELA PATRICIA BENTO DOS SANTOS"& year ==2017& cd_mat ==15724557
				replace nm_mae ="ISABELA CRISTINA FERREIRA DE SOUZA" if name_student =="JONAS RODRIGO DE SOUZA"& year ==2016& cd_mat ==15825680
				replace nm_mae ="ISABELA CRISTINA FERREIRA DE SOUZA" if name_student =="JONAS RODRIGO DE SOUZA"& year ==2017& cd_mat ==15825680
				replace nm_mae ="ISABELA CRISTINA FERREIRA DE SOUZA" if name_student =="JONAS RODRIGO DE SOUZA"& year ==2018& cd_mat ==15825680
				replace nm_mae ="ANA CRISTINA DA SILVA" if name_student =="LEONI EVERTON DA SILVA MOURA"& year ==2017& cd_mat ==16035496
				replace nm_mae ="HOZANA MARIA CAVALCANTE DA SILVA" if name_student =="MARIA CLARA DA SILVA MACHADO"& year ==2017& cd_mat ==16117786
				replace nm_mae ="HOZANA MARIA CAVALCANTE DA SILVA" if name_student =="MARIA CLARA DA SILVA MACHADO"& year ==2018& cd_mat ==16117786
				replace nm_mae ="CRISTIANA MORAIS DA SILVA" if name_student =="MARIA CLARA MORAIS DO NASCIMENTO"& year ==2017& cd_mat ==16676432
				replace nm_mae ="CRISTIANA MORAIS DA SILVA" if name_student =="MARIA CLARA MORAIS DO NASCIMENTO"& year ==2018& cd_mat ==16676432
				replace nm_mae ="WILMA ROSE DAMASIO DA SILVA NUNES" if name_student =="WILLIAM GOMES DA SILVA"& year ==2017& cd_mat ==16738012
				replace nm_mae ="ROZEANE FERNANDES DE LIMA DAS MERCES" if name_student =="RAYZA VITORIA PADILHA DE LIMA"& year ==2017& cd_mat ==16759796
				replace nm_mae ="MICHELE DA CONCEICAO DUARTE DA SILVA" if name_student =="ORLANDO AYALA DUARTE DE MELO"& year ==2017& cd_mat ==16787420
				replace nm_mae ="JACILENE CARLOS DA SILA" if name_student =="DEBORA EVELIN DA SILVA NASCIMENTO"& year ==2018& cd_mat ==17054079
				replace nm_mae ="ROSINEIDE MARTIS RODRIGUES" if name_student =="LHYZANDRA RODRIGUES DE BRITO"& year ==2018& cd_mat ==17058341
				replace nm_mae ="PATRICIA MARIA PANTA NETO" if name_student =="KAYLANE PANTA NETO DE ANDRADE"& year ==2018& cd_mat ==17654092
				replace nm_mae ="CRISTIANA MORAIS DA SILVA" if name_student =="MARIA CLARA MORAIS DO NASCIMENTO"& year ==2016& cd_mat ==16676432
				replace nm_mae ="MICHELE DA CONCEICAO DUARTE" if name_student =="ORLANDO AYALA DUARTE DE MELO"& year ==2017& cd_mat ==16787420
				replace nm_mae ="JACILENE CARLOS DEA SILVA" if name_student =="DEBORA EVELIN DA SILVA NASCIMENTO"& year ==2018& cd_mat ==17054079
				atencao
				}				
			}
			drop erro max_erro mae
			save "$dtinter\clean-names.dta", replace
			*/
			
			
			*Same students with the same identification code
			*----------------------------------------------------------------------------------------------------------------------------------------------------- *			
			{
			use  "$dtinter\clean-names.dta",clear	
			
				**
				*Identifying date of birth for those without this info in a specific year
				sort	 	cd_mat year
				count if 	dt_nasc[_n] != dt_nasc[_n-1] &  cd_mat[_n] == cd_mat[_n-1] & name_student[_n] == name_student[_n-1] & nm_mae[_n] == nm_mae[_n-1]
				replace  	dt_nasc 	 = dt_nasc[_n-1] if cd_mat[_n] == cd_mat[_n-1] & name_student[_n] == name_student[_n-1] & nm_mae[_n] == nm_mae[_n-1] & dt_nasc[_n] != dt_nasc[_n-1] & dt_nasc[_n-1] != . //nesse caso, vamos considerar a data de nascimento, a primeira data de nascimento que aparece no painel
				drop  	 	DATANASC	
				order 	 	rpa year codschool cd_mat turma type_program
				sort 		name_student dt_nasc nm_mae	
				
				**	
				egen 		group = group(name_student dt_nasc nm_mae) 					if !missing(name_student) & !missing(dt_nasc) & !missing(nm_mae) & (length(name_student) > 24 | length(nm_mae) > 24)	   	 		//identificação do estudante, tem estudante sem data de nascimento, nesse caso, group = .
				sort 		group year
				
				**	
				gen 		trocar = 1 													if group[_n] == group[_n-1] & cd_mat[_n] != cd_mat[_n-1] & !missing(group)	
				bys 		group: egen max_trocar = max(trocar)
				br 			group cd_mat year name_student dt_nasc nm_mae max_trocar  	if max_trocar == 1																//alunos que precisamos corrigir o codigo da matricula para que este codigo permaneca o mesmo ao longo do painel
				codebook 	group 														if max_trocar == 1
				drop 		trocar max_trocar
				
				**
				sort 		group year 
				replace	    cd_mat = cd_mat[_n-1]										if group[_n] == group[_n-1] & cd_mat[_n] != cd_mat[_n-1] & !missing(group)		//muitos alunos duplicados e com o mesmo status. quando eles estao duplicados, na maior parte das vezes o codigo da matricula muda
				
				**
				duplicates 	report cd_mat year																															//alguns casos duplicados que vamos corrigir + abaixo.											
			}
			
			
			*Removing duplicate observations
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{   //Alunos que precisam ser excluídos -> alunos que aparecem duas vezes em um mesmo ano
					duplicates 	tag cd_mat year, gen(tag)							
				bys 		cd_mat: egen max_tag = max(tag)		
				br 			year codschool group cd_mat name_student dt_nasc nm_mae grade status type_program tag if max_tag == 1
				
				**
				*Mesmo ano, mesma serie, mesma escola, status diferentes
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort 		cd_mat year	
				gen 		erro = 1 if year[_n] == year[_n+1] & cd_mat[_n] == cd_mat[_n+1] & type_program[_n] == type_program[_n+1] & codschool[_n] == codschool[_n+1] & grade[_n] == grade[_n+1] & status[_n] != status[_n+1]
		
				**
				*Mesmo ano, mesma serie, mesmo status, escolas diferentes
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort 		cd_mat year	
				replace 	erro = 1 if year[_n] == year[_n+1] & cd_mat[_n] == cd_mat[_n+1] & type_program[_n] == type_program[_n+1] & codschool[_n] != codschool[_n+1] & grade[_n] == grade[_n+1] & status[_n] == status[_n+1]

				**
				*Mesmo ano, mas series diferentes
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort 		cd_mat year	
				replace 	erro = 1 if year[_n] == year[_n+1] & cd_mat[_n] == cd_mat[_n+1] & type_program[_n] == type_program[_n+1] 									& grade[_n] != grade[_n+1] 

				**
				*Estudantes com os erros identificados acima, mas que nunca participaram do SE LIGA/ACELERA
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort cd_mat
				bys 		cd_mat: egen max_erro = max(erro)
				bys			cd_mat: egen none = max(type_program)
				
				*------------------------------------>>
				count
				drop 		if max_erro == 1 & none == 1				//sample size reduction with this strategy 891/773405
				*------------------------------------>>
				drop 		erro max_erro tag max_tag none
				
				**
				*Alunos com ano=ano[_n-1] & cd_mat=cd_mat[_n-1] & status=status[_n-1] & type_program=type_program[_n-1] & serie[_n] == serie[_n+1]
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort 		cd_mat year
				drop 		if year[_n] == year[_n+1] & cd_mat[_n] == cd_mat[_n+1] & type_program[_n] == type_program[_n+1] & codschool[_n] == codschool[_n+1] & grade[_n] == grade[_n+1] & status[_n] == status[_n+1]				
				
				**
				*Se o aluno foi transferido, ele também aparece duas vezes em um mesmo ano
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort 		cd_mat year status	
				drop 		if year[_n] == year[_n+1] & cd_mat[_n] == cd_mat[_n+1] & status[_n] == 0 //aluno com status de transferido, então consideramos como ele aparece em n+1
				
				**
				*Em t aparece que dropped em uma escola, mas que approved ou repeated em outra no mesmo ano, nesse caso vamos excluir a informação de que dropped porque é mais provável que o aluno tenha sido transferido aí aprovado ou reprovado na outra escola
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort 		cd_mat year status		
				drop 		if year[_n] == year[_n-1] & cd_mat[_n] == cd_mat[_n-1] & type_program[_n] == type_program[_n-1]	& grade[_n] == grade[_n-1] & codschool[_n] != codschool[_n-1] & status[_n] == 3 & (status[_n-1] == 1 | status[_n-1] == 2)

				**
				*Mesmo ano, diferentes escolas, uma sem status e outra com status
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort 		cd_mat year status		
				drop 		if year[_n] == year[_n-1] & cd_mat[_n] == cd_mat[_n-1] & type_program[_n] == type_program[_n-1]	& grade[_n] == grade[_n-1] & codschool[_n] != codschool[_n-1] & status[_n] == 5
				
				**
				*Mesmo ano, em um aprovado em outro reprovado, mas a serie[_n+1] = serie[_n] + 1
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort 		cd_mat year status		
				drop 		if year[_n] == year[_n-1] & cd_mat[_n] == cd_mat[_n-1] & cd_mat[_n] == cd_mat[_n+1] & status[_n] == 2 & status[_n-1] == 1 & grade[_n] == grade[_n+1] - 1
				
				**
				*Mesmo ano, em um aprovado em outro reprovado, mas a serie[_n+1] = serie[_n]
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort 		cd_mat year status		
				drop 		if year[_n] == year[_n+1] & cd_mat[_n] == cd_mat[_n+1] & cd_mat[_n] == cd_mat[_n+2] & status[_n] == 1 & status[_n+1] == 2 & grade[_n+1] >= grade[_n+2]
				
				**
				*Alunos com ano=ano[_n-1] & cd_mat=cd_mat[_n-1] & status=status[_n-1] & type_program=type_program[_n-1] & serie[_n] == serie[_n+1]
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort 		cd_mat year
				drop 		if year[_n] == year[_n+1] & cd_mat[_n] == cd_mat[_n+1] & type_program[_n] == type_program[_n+1] & codschool[_n] == codschool[_n+1] & grade[_n] == grade[_n+1] & status[_n] == status[_n+1]				
				
				**
				*Demais casos, 
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				duplicates 	tag cd_mat year, gen(tag)							
				bys 		cd_mat: egen max_tag = max(tag)		
				br 			year codschool group cd_mat name_student dt_nasc nm_mae grade status type_program tag if max_tag == 1

				
				br 	group cd_mat year name_student codschool grade status type_program		if inlist(cd_mat, 6008380 , 11612460, 12965944, 13307215, 14206234)
				br 	group cd_mat year name_student codschool grade status type_program		if inlist(cd_mat, 3384047, 13307215,14291940)
				drop	 	if   cd_mat == 3384047   & year == 2009 
				drop		if   cd_mat == 3384047   & year == 2008
				drop 		if   cd_mat == 3384047   & year == 2011 & grade  == 3
				drop 		if 	(cd_mat == 6008380   & year == 2015 & grade  == 3) | (cd_mat == 6008380 & year == 2016 & grade == 4)		
				drop 		if   cd_mat == 6080375   & year == 2012 & status == 5
				drop 		if   cd_mat == 7034814   & year == 2008 & grade == 2
				drop 		if   cd_mat == 8191328 & year == 2014 & codschool == 26128888
				drop 		if   cd_mat == 9165452 & year ==2014 & grade == 2 
				drop 		if 	 cd_mat == 11612460 
				drop 		if 	 cd_mat == 12965944  & year == 2015 & grade  == 1
				drop 		if 	 cd_mat == 12965944  & year == 2016 & grade  == 2
				drop 		if 	 cd_mat == 12965944  & year == 2018 & grade  == 3
				drop 		if   cd_mat == 13307215  & year == 2014 & codschool == 26127008
				drop 		if   cd_mat == 14095220  & year ==2015 & type_program== 1
				drop 		if   cd_mat == 14206234  & year == 2014 & grade == 2
				drop 		if   cd_mat == 14305704
				drop 		if   cd_mat == 14334909  & year == 2015 & grade  == 2
				drop 		if   cd_mat == 15685071  & year == 2015 & grade  == 3 & type_program == 1
				drop 		if   cd_mat == 2018080 & year ==2008 & grade == 2 & status == 3
				drop 		if   cd_mat == 3382028
				drop 		if   cd_mat == 12932868 & year ==2012 & grade == 1 & status == 5
				drop	 	if   cd_mat == 15675149 & year == 2015 & type_program == 2
				drop		if   cd_mat == 14070731 & year == 2014 & grade== 2
				drop	 	if   cd_mat == 14291940	
				sort 		 	 cd_mat year
				
				
				
				**
				*Checking if we still have duplicates
				* ------------------------------------------------------------------------------------------------------------------------------------------------- *
				sort cd_mat year
				drop tag max_tag
				duplicates 	tag cd_mat year, gen(tag)							
				bys 		cd_mat: egen max_tag = max(tag)		
				sort 		cd_mat year	
				br 			year codschool group cd_mat name_student dt_nasc nm_mae grade status type_program tag if max_tag == 1
				assert max_tag == 0
				duplicates  examples cd_mat year		//OK!!!	
				drop 	    group  
				drop tag max_tag
			}
			

			
			*Same school, name of the student, mother's , same year and same birthday, but distinct code of enrollment. 
			*----------------------------------------------------------------------------------------------------------------------------------------------------- *			
			{
			sort year codschool name_student nm_mae 
			count 		 if codschool[_n] == codschool[_n-1] & name_student[_n] == name_student[_n-1] & nm_mae[_n] == nm_mae[_n-1] & year[_n] == year[_n-1] & dt_nasc[_n] == dt_nasc[_n-1] & cd_mat[_n] != cd_mat[_n-1]
			gen erro = 1 if codschool[_n] == codschool[_n-1] & name_student[_n] == name_student[_n-1] & nm_mae[_n] == nm_mae[_n-1] & year[_n] == year[_n-1] & dt_nasc[_n] == dt_nasc[_n-1] & cd_mat[_n] != cd_mat[_n-1]
			bys  	year codschool name_student nm_mae : egen max_erro = max(erro)
			br 		year cd_mat codschool name_student dt_nasc nm_mae grade type_program if max_erro == 1
			bys 	cd_mat: gen times = _N
			bys 	cd_mat: egen max_erro2 = max(max_erro)
			sort 	name_student grade year
			br 		year cd_mat codschool times name_student dt_nasc nm_mae grade type_program if max_erro2 == 1
			drop 	if  times == 1 & max_erro == 1
			drop 	max_erro erro max_erro2 times
			}
			
			
			*Correcting the status of the student
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{	//Tem alguns alunos sem status mas conseguimos descobrir: por exemplo, 2011 1 ano sem status, 2012 2ano, significa que ele foi aprovado
				sort cd_mat year
			
				**
				*Serie_n = serie_n+1 - 1
				replace status = 1 if cd_mat[_n] == cd_mat[_n+1] & year[_n] == year[_n+1] - 1 &  grade[_n] == grade[_n+1] - 1  & status[_n] == 5 //em n está sem status
			
				**
				*Aluno aparece como reprovado mas a série muda
				replace status = 1 if cd_mat[_n] == cd_mat[_n+1] & year[_n] == year[_n+1] - 1 &  grade[_n] == grade[_n+1] - 1  & status[_n] == 2
				
				**
				*Série_n = série n+1 , aluno reprovado
				replace status = 2 if cd_mat[_n] == cd_mat[_n+1] & year[_n] == year[_n+1] - 1 &  grade[_n] == grade[_n+1] 	   & status[_n] == 5 //em n está sem status
				
				**
				*Muitos casos em que o aluno aparece como aprovado mas a série não muda
				replace status = 2 if cd_mat[_n] == cd_mat[_n+1] & year[_n] == year[_n+1] - 1 &  grade[_n] == grade[_n+1] 	   & status[_n] == 1 //aparece como aprovado
				
				**		
				*Serie_n = serie_n+1 - 2
				replace status = 1 if cd_mat[_n] == cd_mat[_n+1] & year[_n] == year[_n+1] - 1 & (grade[_n] == grade[_n+1] - 2 | grade[_n] == grade[_n+1] - 3 | grade[_n] == grade[_n+1] - 4) & status[_n] == 5
				
				**
				*Série n = serie_n-1 + 1
				replace status = 1 if cd_mat[_n] == cd_mat[_n+1] & year[_n] == year[_n+1] - 1 &  grade[_n] <= grade[_n+1] - 1  & status[_n] == 0	 	//aluno transferido mas sabemos que foi aprovado  porque a serie muda
				replace status = 2 if cd_mat[_n] == cd_mat[_n+1] & year[_n] == year[_n+1] - 1 &  grade[_n] == grade[_n+1] 	   & status[_n] == 0 		//aluno transferido mas sabemos que foi reprovado porque serie n+1 = serie n 
				
				**
				*Aluno que aparece como dropped, mas ele consta no ano seguinte na base de dados
				replace status = 1 if cd_mat[_n] == cd_mat[_n+1] & year[_n] == year[_n+1] - 1 &  grade[_n] <= grade[_n+1] - 1  & status[_n] == 3 
				replace status = 2 if cd_mat[_n] == cd_mat[_n+1] & year[_n] == year[_n+1] - 1 &  grade[_n] == grade[_n+1] 	   & status[_n] == 3 
				
				**
				*Aluno que aparece como aprovado, mas houve uma regressao na serie entre t e t+1
				replace status = 2 if cd_mat[_n] == cd_mat[_n+1] & year[_n] == year[_n+1] -1 & grade[_n] > grade[_n+1]		   & status[_n] == 1
				
				**
				*Alunos falecidos ou com missing status
				sort		 cd_mat year
				forvalues	 i = 1(1)5 {
					replace	 status =  4 if status[_n-1] == 4 & cd_mat[_n] == cd_mat[_n-1]
				}
				drop	 if  status == 4				
								
				**
				tab status, mis
				
				**
				tab year status 																														//now we see that there are several observations without status between 2015-2018
			}
			
			
			*Correcao da variavel idade
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				gen  		inicio_aula = date("02/" + "01/" + string(year), "MDY")
				format  	inicio_aula %td
				gen	    	idade = (inicio_aula - dt_nasc)/365.25										//idade no início das aulas
				drop 		inicio_aula
				bys 		cd_mat: egen min_idade = min(idade)
				bys 		cd_mat: egen max_idade = max(idade)

				**
				replace 	idade = . 	if max_idade < 0 & min_idade < 0								//a idade eh sempre negativa. 
				
				**
				drop 		max_idade min_idade
				su 			idade, detail
			}	
			

			*Alunos que "regrediram" uma serie
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *			
			{
				/*
				//Alguns alunos aparecem no 6o ano por ex em 2012 e depois aparecem no painel de novo no 5o ano em 2015
				sort 	cd_mat year
				gen 	dif = grade[_n] - grade[_n-1] if cd_mat[_n] == cd_mat[_n-1]			//aluno que regrediu de serie
				tab 	dif
				bys 	cd_mat: egen error = min(dif)
				tab 	type_program if dif == 0
				
				gen erro = 1 if dif < 0 & type_program == 1
				bys cd_mat: egen max_erro = max(erro)
				
				sort cd_mat year
				br cd_mat year grade status name_student nm_mae dt_nasc if max_erro == 1
				drop if max_erro == 1
				
				//pode ser claramente um erro de preenchimento de turma, ou que de fato o aluno "regrediu" um ou dois anos, ou depois de um abandono ou para poder participar do SLA
				br 		cd_mat year grade status name_student dt_nasc idade type_program dif error if error < 0 //there are observations that we can clearly see its a mistake
				
				bys cd_mat: egen max_year_dif_neg = max(year) if dif < 0
				bys cd_mat: egen temp = max(max_year_dif_neg)
				drop if year <=temp & error < 0 
				
				drop dif error erro max_erro max_year_dif_neg temp
				*/
				/*
				sort 	cd_mat year
				gen 	dif = grade[_n] - grade[_n-1] if cd_mat[_n] == cd_mat[_n-1]			//aluno que regrediu de serie
				tab 	dif
				bys 	cd_mat: egen error = min(dif)
				tab 	type_program if dif == 0
				
				gen erro = 1 if dif < 0 & type_program == 1
				bys cd_mat: egen max_erro = max(erro)
				
				sort cd_mat year
				br cd_mat year grade status name_student nm_mae dt_nasc if max_erro == 1
				*/
			}				
			

			*Alunos cuja idade minima ou maxima no painel eh outlier
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				
				bys    cd_mat: egen min_idade = min(idade)
				su 		min_idade, detail
				replace idade = . 		if min_idade < r(p1) | min_idade > r(p99)
				
				**
				drop 		min_idade
			}
			

			
			*Idade adequada para a serie
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{ // e diferenca com relacao a idade adequada
				local 		adequada       = 6 
				gen   		idade_adequada = .
				forvalues 	serie = 1(1)9 {
					replace idade_adequada = `adequada'        		if grade == `serie'
					local   adequada       = `adequada' + 1
				}
				gen 		dif_adequada   = idade_adequada - idade if !missing(idade)
				su 	dif_adequada, detail
				*gen atencao = 1 if dif_adequada < r(p1) | (dif_adequada > r(p99) & !missing(dif_adequada))
				*sort cd_mat year
				*br 	 cd_mat year dt_nasc idade grade dif_adequada atencao
			}	
								
				
			
			*Code of the classrooms
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
			    replace period = 6 if period == .
				egen 		cd_turma  = group(turma codschool year grade period) 

			}		


			*Diferenca com relacao à idade media da turma
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				bys 		cd_turma: egen idade_media_turma = mean(idade)
				
				**
				gen 		dif_idade_media = idade - idade_media_turma if 						  !missing(idade) & !missing(idade_media_turma)
				
				su 			dif_idade_media, detail				
				gen  		erro = 1 							  		if dif_idade_media < r(p1) | dif_idade_media > r(p99)
				
				bys 		cd_mat: egen max_erro = max(erro)
				replace 	idade = . if max_erro == 1 
				drop 		erro max_erro
				replace 	dif_adequada = . if missing(idade)
				
				**
				drop 	    idade_adequada
			}
			
			
			*Alunos com distorcao idade-serie
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				**
				sort 		cd_mat year
				gen 		dist_2mais =.
				gen 		dist_1mais =.
				gen 		distorcao  = .
				local   	adequada = 6								//idade adequada para o início do 1o ano 
				
				**
				forvalues serie = 1(1)9 {	
					replace dist_2mais = 1 if idade >= `adequada' + 2 & !missing(idade) & grade == `serie'
					replace dist_1mais = 1 if idade >= `adequada' + 1 & !missing(idade) & grade == `serie'
					replace distorcao  = idade - `adequada' if 	        !missing(idade) & grade == `serie'
					local   adequada   = `adequada' + 1 
				}
				
				**
				replace dist_1mais = 0 if dist_1mais == . & !missing(idade)
				replace dist_2mais = 0 if dist_2mais == . & !missing(idade)	
			}
				
				
			*Variáveis dependentes do estudo
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				**
				gen 	approved   = 1 if status == 1
				replace approved   = 0 if status == 2 | status == 3
				
				**
				gen 	repeated   = 1 if status == 2
				replace repeated   = 0 if status == 1 | status == 3
				
				**
				gen 	dropped    = 1 if status == 3
				replace dropped    = 0 if status == 1 | status == 2
				
				**
				sort 	cd_mat year
			}
		
		
			*Escola que adotou o programa
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				gen 	A = type_program > 1
				bys 	codschool year: egen tem_programa_nesse_ano = max(A)				//1 if the school has SE LIGA or ACELERA in year t
				drop    A
				
				gen 	A = type_program == 2
				bys 	codschool year: egen tem_seliga_nesse_ano   = max(A)				//1 if the school has SE LIGA  in year t
				drop    A
				
				gen 	A = type_program == 3
				bys 	codschool year: egen tem_acelera_nesse_ano  = max(A)				//1 if the school has  ACELERA in year t
				drop    A
			}
				
				
			*Quantas séries conseguiu pular
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				sort 	cd_mat year
				
				foreach program in 1 2 3 {
					
					**
					gen	  	pulou1_program`program' 		= 1 if grade[_n+1] == grade[_n] + 1 & cd_mat[_n+1] == cd_mat[_n] & (type_program == `program') & year[_n+1] == year[_n] + 1
					gen	  	pulou2_program`program'  		= 1 if grade[_n+1] >  grade[_n] + 1 & cd_mat[_n+1] == cd_mat[_n] & (type_program == `program') & year[_n+1] == year[_n] + 1

					**
					gen   	reprovou_`program'   	 		= 1 if (type_program == `program') & status == 2
					gen   	abandonou_`program'  	 		= 1 if (type_program == `program') & status == 3
					gen   	aprovou_`program'  		 		= 1 if (type_program == `program') & status == 1	
					
					gen 	aprovou_semdepois_`program'   	= 1 if aprovou_`program'  == 1 & 	  cd_mat[_n] != cd_mat[_n+1] 
					
				}
			}
			
			
			*Alunos que migraram para o SE LIGA/ACELERA
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				sort 	cd_mat year
				
				gen 	programa_posterior 		= type_program[_n+1] 										if cd_mat[_n] == cd_mat[_n+1]  & year[_n] == year[_n+1] - 1			
				gen 	alunovaimigrar_seliga	= programa_posterior == 2 & !missing(programa_posterior)	if cd_mat[_n] == cd_mat[_n+1]  & year[_n] == year[_n+1] - 1	& type_program == 1							//aluno que migrou para o sla
				gen 	alunovaimigrar_acelera	= programa_posterior == 3 & !missing(programa_posterior)	if cd_mat[_n] == cd_mat[_n+1]  & year[_n] == year[_n+1] - 1	& type_program == 1							//aluno que migrou para o sla
				gen	 	status_anterior 		= status[_n-1] 		 										if cd_mat[_n] == cd_mat[_n-1]  & year[_n] == year[_n-1] + 1	
				gen 	status_posterior 		= status[_n+1] 		 										if cd_mat[_n] == cd_mat[_n+1]  & year[_n] == year[_n+1] - 1
				gen 	proxima_serie 			= grade[_n+1] 												if cd_mat[_n] == cd_mat[_n+1]  & year[_n] == year[_n+1] - 1
				gen 	reprovou_anterior 		= 1 				 										if status_anterior == 2
				replace reprovou_anterior 		= 0 														if status_anterior == 1
				
				label 	val status_anterior  status
				label 	val status_posterior status			
			}
				
				
			*Alunos por turma, idade min e max
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				gen 	id = 1
			
				**		
				bys 	cd_turma: egen min_idade_turma 				= min(idade) 											//aluno mais novo	
				bys 	cd_turma: egen max_idade_turma 				= max(idade) 											//aluno mais velho
				bys		cd_turma: egen students_class				= count(id)		 							
				bys	 	cd_turma: egen max_distorcao_turma 			= max(distorcao)
				bys 	cd_turma: egen min_distorcao_turma 			= min(distorcao)
				bys 	cd_turma: egen n_students_age_distortion1 	= count(dist_1mais) 						    		//number of students with one year  of age distortion
				bys 	cd_turma: egen n_students_age_distortion2 	= count(dist_2mais) 						    		//number of students with two years of age distortion
				bys 	cd_turma: egen n_alunosvaomigrar_seliga 	= sum(alunovaimigrar_seliga)	if type_program == 1	//numero de alunos da turma que vao para o SLA
				bys 	cd_turma: egen n_alunosvaomigrar_acelera 	= sum(alunovaimigrar_acelera)	if type_program == 1	//numero de alunos da turma que vao para o SLA
				
				**
				sort    cd_mat year			
				gen 	dif_idade_turma 			 = max_idade_turma - min_idade_turma 		if !missing(min_idade_turma) & !missing(max_idade_turma)										//range de idade (dif entre o mais velho e o mais novo)\
				gen     n_alunos_migraram_seliga	 = n_alunosvaomigrar_seliga[_n-1] 			if cd_mat[_n] == cd_mat[_n-1]  & year[_n] == year[_n-1] + 1 & type_program == 1
				gen     n_alunos_migraram_acelera	 = n_alunosvaomigrar_acelera[_n-1] 			if cd_mat[_n] == cd_mat[_n-1]  & year[_n] == year[_n-1] + 1 & type_program == 1
				gen     dif_idade_turma_ano_anterior = dif_idade_turma[_n-1]  		 			if cd_mat[_n] == cd_mat[_n-1]  & year[_n] == year[_n-1] + 1 & type_program == 1
				label 	val programa_posterior type_program
				
				**
				*tab 	pulou1_a
				*tab 	pulou2_sla
				*tab 	reprovou_sla
				*tab 	abandonou_sla			//we are not able to track how many grades the approved students were able to jump, because a lot of them after 5th grade go to the state network. 
				*tab 	aprovou_sla				//we are not able to track how many grades the approved students were able to jump, because a lot of them after 5th grade go to the state network. 
			}	
				

			*Students included in the intervention after the 5th grade
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				gen 	atencao = 1 if grade > 5 & type_program > 1
				bys 	cd_mat: egen incluido_sla5mais= max(atencao)
				br 		cd_mat status cd_turma codschool year grade type_program incluido_sla5mais if  incluido_sla5mais == 1
				drop 	atencao
			}
			
			
			*Alunos que entraram depois do 6o ano no painel
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *			
			{	//eles nao precisam estar na base de dados
				bys 		 cd_mat: egen primeira_serie_painel  = min(grade)
				drop if 	 primeira_serie_painel > 5									//aluno que definitivamente entrou depois do 6o ano e depois nao regrediu de serie
				drop 		 primeira_serie_painel 
			}	
				
			
			*Identificação dos que já foram tratados
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *			
			{	
				**
				gen 		t_sla 		 = (type_program == 2 | type_program == 3)															//para o ano em que o aluno esta matriculado no programa
				gen 		t_seliga 	 = (type_program == 2)
				gen 		t_acelera 	 = (type_program == 3)
				
				**
				foreach 	type_program in sla seliga acelera {
					bys 	cd_mat: egen `type_program'2014 = max(t_`type_program') if year <= 2014
					bys 	cd_mat: egen `type_program'2018 = max(t_`type_program') if year <= 2018
				}
				
				foreach year in 2014 2018 {
				gen 		only_seliga`year'   = (seliga`year' == 1 & acelera`year' == 0)
				gen 		only_acelera`year'  = (seliga`year' == 0 & acelera`year' == 1)
				gen 		twoprograms`year'   = (seliga`year' == 1 & acelera`year' == 1)
				gen 		none`year'          = (seliga`year' == 0 & acelera`year' == 0)		//nunca participou de nenhum program										
				}
			}			
			
			*Ao longo do histórico do aluno, qual a distorção máximo, quando ele foi inserido no SLA, qual o num. de participações nas intervenções 
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *			
			{ //By class we have: min age of the class, max age of the class, difference between max and min age of the class, number of students per class, number of students that will go from regular to SE LIGA/ACELERA

				sort cd_mat year
			
				**
				bys 		cd_mat: egen first_seliga      		= min(year) if type_program == 2
				bys 		cd_mat: egen first_acelera     		= min(year) if type_program == 3
				bys 		cd_mat: egen min_first_seliga   	= min(first_seliga)
				bys 		cd_mat: egen min_first_acelera   	= min(first_acelera)
				bys         cd_mat: egen primeiro_ano_painel    = min(year)
				
				**
				gen 		num_parti_acelera = 1 							if year == min_first_acelera
				replace 	num_parti_acelera = num_parti_acelera[_n-1]  	if (num_parti_acelera[_n-1] >= 1) & !missing(num_parti_acelera[_n-1]) & cd_mat[_n] == cd_mat[_n-1] & t_acelera == 0
				replace 	num_parti_acelera = num_parti_acelera[_n-1] + 1 if (num_parti_acelera[_n-1] >= 1) & !missing(num_parti_acelera[_n-1]) & cd_mat[_n] == cd_mat[_n-1] & t_acelera == 1
			
				**
				gen 		num_parti_seliga = 1 							if year == min_first_seliga
				replace 	num_parti_seliga = num_parti_seliga[_n-1]     	if (num_parti_seliga[_n-1]  >= 1) & !missing(num_parti_seliga[_n-1])  & cd_mat[_n] == cd_mat[_n-1] & t_seliga  == 0
				replace 	num_parti_seliga = num_parti_seliga[_n-1] + 1   if (num_parti_seliga[_n-1]  >= 1) & !missing(num_parti_seliga[_n-1])  & cd_mat[_n] == cd_mat[_n-1] & t_seliga  == 1
				
				**
				replace 	num_parti_seliga 		= 0 if num_parti_seliga  == .
				replace 	num_parti_acelera 		= 0 if num_parti_acelera == .
				gen 		ja_participou_seliga  	= year > min_first_seliga 
				gen 		ja_participou_acelera 	= year > min_first_acelera
				
			}	
			
		
			*Qual a distorcao de quem participa dos programas
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				su 		distorcao if type_program  == 2 & year == min_first_seliga, detail	//90% tem distorcao > 1 ano
				su 		distorcao if type_program  == 3 & year == min_first_acelera, detail	//95% tem distorcao > 1 ano	
			}	
			

				
			*Migrou de escola para participar do se liga, acelera
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				sort cd_mat year
				
				gen		trocou_escola_seliga   = 1 if type_program[_n] == 2 & cd_mat[_n] == cd_mat[_n-1] & type_program[_n-1] == 1 & codschool[_n] != codschool[_n-1] & year == min_first_seliga
				replace trocou_escola_seliga   = 0 if type_program[_n] == 2 & cd_mat[_n] == cd_mat[_n-1] & type_program[_n-1] == 1 & codschool[_n] == codschool[_n-1] & year == min_first_seliga
				
				gen		trocou_escola_acelera  = 1 if type_program[_n] == 3 & cd_mat[_n] == cd_mat[_n-1] & type_program[_n-1] == 1 & codschool[_n] != codschool[_n-1] & year == min_first_acelera
				replace trocou_escola_acelera  = 0 if type_program[_n] == 3 & cd_mat[_n] == cd_mat[_n-1] & type_program[_n-1] == 1 & codschool[_n] == codschool[_n-1] & year == min_first_acelera
			}
				

			*Grupos elegíveis/entraram no SLA
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{	
				**
				forvalues serie = 1(1)5 {
					gen el2_`serie'ano 			= 1 if (grade == `serie') & distorcao   >= 1 & !missing(distorcao) & status_anterior == 2 & year >= 2010						//quando elegivel ao programa e reprovou em t-1
					gen el1_`serie'ano 			= 1 if (grade == `serie') & distorcao   >= 1 & !missing(distorcao)						  & year >= 2010					//quando elegivel ao programa
					gen en_`serie'ano_acelera 	= 1 if (grade == `serie'  &  (type_program == 3 ))
				}
				
				**
				**
				gen 		entrou_nesse_ano_acelera 	= .
				gen 		el1_nesse_ano 				= .
				gen 		el2_nesse_ano				= .
				
				**
				forvalues serie = 1(1)5 {
					replace el1_nesse_ano 		  			= 1 if el1_`serie'ano		 	== 1 & grade == `serie' & year >= 2010
					replace el2_nesse_ano 		  			= 1 if el2_`serie'ano		 	== 1 & grade == `serie' & year >= 2010
					replace entrou_nesse_ano_acelera  	  	= 1 if en_`serie'ano_acelera	== 1 & grade == `serie' & year >= 2010
				}
				
				**
				gen 	d_seliga  =  t_seliga  == 1 | ja_participou_seliga  == 1 //dummy que assume valor 1 no ano que o aluno participa do programa ou depois
				gen 	d_acelera =  t_acelera == 1 | ja_participou_acelera == 1
		
		
				gen 		depois_acelera			= 1 if year>=  min_first_acelera & !missing(min_first_acelera)
				replace	 	depois_acelera 			= 0 if year <  min_first_acelera & !missing(min_first_acelera)
				
				bys cd_mat: egen Amin_elegivel = min(year) if el1_nesse_ano == 1
				bys cd_mat: egen  min_elegivel = max(Amin_elegivel)
				
				replace 	depois_acelera 			= 1 if year >= min_elegivel & none2014 == 1 & !missing(min_elegivel)
				replace 	depois_acelera			= 0 if year <  min_elegivel & none2014 == 1 & !missing(min_elegivel)
				
				bys cd_mat: egen jafoielegivel = max(el1_nesse_ano) 
				
				replace 	depois_acelera = 0 if (year < 2010 & acelera2014 == 1) | (year< 2010 & jafoielegivel == 1)
		
			}	

			*Formatting
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{	
				
				**
				label 	define yesno			0 "No" 1 "Yes"
				
				/*
				**
				foreach var of varlist el* entrou* el* en_* only* alunovaimigrar_* dist_1mais dist_2mais tem_programa_nesse_ano approved repeated dropped t_* seliga* acelera* none* twoprograms* reprovou_anterior ja_participou* pulou* abandonou_* reprovou_* aprovou* {
					label val `var' yesno
				}
				*/
				
				set    seed 487499
				
				**
				sort   cd_mat
				
				**
				gen  		id_emprel = _n
				
				**
				format idade dif_adequada distorcao  min_idade_turma max_idade_turma max_distorcao_turma min_distorcao_turma dif_idade_turma dif_idade_turma_ano_anterior %4.2fc
				
				**
				drop   id *first*
				
	
			*Student's name -> to try to find the students in the SAEPE dataset 
			* ----------------------------------------------------------------------------------------------------------------------------------------------------- *
			{
				split 	name_student, limit(3) gen(first_name)
				gen 	sizename1 = length(first_name1)
				gen 	sizename2 = length(first_name2)
				gen 	sizename3 = length(first_name3)
			}	
								
				/*
				**
				label 	var grade 													"Grade"
				label 	var type_program 											"Program student is enrolled"
				label 	var rpa 													"Região adm"
				label 	var year 													"Ano"
				label 	var codschool			 									"Cod INEP Escola"
				label 	var cd_mat 													"Cod Matrícula"
				label 	var cd_turma 												"Cod Turma"
				label 	var cd_turma 											""
				label 	var type_program 											"1 = Regular, 2 = Se Liga, 3 =  Acelera"
				label 	var grade 													"Série"
				label 	var period 													"Período"
				label 	var name_student 											"Nome do aluno"
				label 	var gender 													"Gênero"
				label 	var nm_mae 													"Nome da mãe"
				label 	var status 													"Status no final do ano"
				label 	var dt_nasc 												"data de nascimento"
				label 	var t_sla 													"Se Liga/Acelera em t"
				label 	var t_seliga 												"Se Liga em t"
				label	var t_acelera 												"Acelera em t"
				**label 	var sla* 													"Participou Se Liga,Acelera"
				*label 	var seliga* 													"Participou do Se Liga"
				*label 	var acelera* 												"Participou do Acelera"
				*label 	var only_seliga* 											"Somente participou do Se Liga"
				*label 	var only_acelera* 											"Somente participou do Acelera"
				*label 	var twoprograms* 											"Já participou dos dois"
				*label 	var none* 													"Nunca participou de nenhum"
				label 	var idade 													"Idade"
				label 	var dif_adequada 											"Diferença entre a idade e a idade adequada série"
				label 	var dist_2mais 												"1 se distorção >= 2"
				label 	var dist_1mais 												"1 se distorção >= 1"
				label 	var distorcao 												"Distorção, em anos"
				label 	var num_parti 												"Número de participações Se Liga, Acelera"
				label	var num_parti_seliga 										"Número de participações no Se Liga"
				label 	var num_parti_acelera 										"Número de participações no Acelera"
				label 	var max_distorcao_aluno 									"Máxima distorção apresentada pelo aluno na amostra"
				label 	var min_distorcao_aluno 									"Mínima distorção apresentada pelo aluno na amostra"
				label 	var primeiro_ano_painel 									"Primeiro ano que o aluno apareceu no painel"
				label 	var ultimo_ano_painel 										"Último ano que o aluno apareceu no painel"
				label 	var num_vezes_painel 										"Número de vezes o painel"
				label 	var primeiro_ano_distorcao 									"Primeiro ano que o aluno apresentou distorção"
				label 	var primeira_serie_seliga  									"Primeira série no Se Liga"
				label 	var primeira_serie_seliga  									"Primeira série no Acelera"
				label 	var approved 												"Aprovado"
				label 	var repeated 												"Reprovado"
				label 	var dropped 												"Abandonou"
				label 	var tem_programa_nesse_ano 									"Escola oferece o programa em t"
				label 	var programa_posterior 										"Programa em que o aluno está matriculado em t + 1"
				label 	var alunovaimigrar_seliga 									"Aluno migrou para o Se Liga em t + 1"
				label 	var alunovaimigrar_acelera 									"Aluno migrou para o Acelera em t + 1"
				label 	var status_anterior 										"Status em t - 1"
				label 	var status_posterior	 "Status em t + 1"
				label 	var reprovou_anterior "Reprovou em t - 1"
				label 	var ja_participou_seliga "Em t já participou do Se Liga antes de t"
				label 	var ja_participou_acelera "Em t já participou do Acelera antes de t"
				label 	var pulou1_program1 "Matriculado na Educ Regular em t e pulou uma série"
				label 	var pulou2_program1 "Matriculado na Educ Regular em t e pulou duas séries"
				label 	var reprovou_1 "Matriculado na Educ Regular em t e reprovou"
				label 	var abandonou_1 "Matriculado na Educ Regular em t e abandonou"
				label 	var aprovou_1 "Matriculado na Educ Regular em t e aprovou"
				label 	var aprovou_semdepois_1 "Matriculado na Educ Regular em t mas sem a série em t+1 para eu saber  quantas séries pulou"
				label 	var pulou1_program2 "Matriculado na Educ Regular em t e pulou uma série"
				label 	var pulou2_program2 "Matriculado Se Liga em t e pulou duas séries"
				label 	var reprovou_2 "Matriculado Se Liga em t e reprovou"
				label 	var abandonou_2 "Matriculado Se Liga em t e abandonou"
				label 	var aprovou_2 "Matriculado Se Liga em t e aprovou"
				label 	var aprovou_semdepois_2 "Matriculado Se Liga em t mas sem a série em t+1 para eu saber  quantas séries pulou"
				label 	var pulou1_program3 "Matriculado Acelera em t e pulou uma série"
				label 	var pulou2_program3 "Matriculado Acelera em t e pulou duas séries"
				label 	var reprovou_3 "Matriculado Acelera em t e reprovou"
				label 	var abandonou_3 "Matriculado Acelera em t e abandonou"
				label 	var aprovou_3 "Matriculado Acelera em t e aprovou"
				label 	var aprovou_semdepois_3 "Matriculado Acelera em t mas sem a série em t+1 para eu saber  quantas séries pulou"
				label 	var min_idade_turma "Menor idade da turma em que o aluno está matriculado"
				label 	var max_idade_turma "Maior idade da turma em que o aluno está matriculado"
				label 	var students_class "Alunos por turma"
				label 	var max_distorcao_turma "Máxima distorção apresentada pela turma"
				label 	var min_distorcao_turma "Mínima distorção apresentada pela turma"
				label 	var n_students_age_distortion1 "Número de alunos da turma com distorção de um ano ou mais"
				label 	var n_students_age_distortion2 "Número de alunos da turma com distorção de dois anos ou mais"
				label 	var n_alunosvaomigrar_seliga "Número de alunos da turma que migraram para o Se Liga em t + 1"
				label 	var n_alunosvaomigrar_acelera "Número de alunos da turma que migraram para o Acelera em t + 1"
				label 	var dif_idade_turma "Diferença entre a idade máxima e a idade mínima da turma em t"
				label 	var n_alunos_migraram_sla "Número de alunos da turma do aluno i que foram alocados no Se Liga, Acelera em t"
				label 	var n_alunos_migraram_seliga "Número de alunos da turma do aluno i que foram alocados no Se Liga em t"
				label 	var n_alunos_migraram_acelera "Número de alunos da turma do aluno i que foram alocados no Acelera em t"
				label 	var dif_idade_turma_ano_anterior "Diferença entre a idade máxima e a idade mínima da turma em t -1"
				label 	var min_first_sla "Primeiro ano que o aluno participou do Se Liga, Acelera"
				label 	var min_first_seliga "Primeiro ano que o aluno participou do Se Liga"
				label 	var min_first_acelera "Primeiro ano que o aluno participou do Acelera"
				/*
				label 	var Dlag_0 ""
				label 	var Dlead_0 ""
				label 	var Dlag_1 ""
				label 	var Dlead_1 ""
				label 	var Dlag_2 ""
				label 	var Dlead_2 ""
				label 	var Dlag_3 ""
				label 	var Dlead_3 ""
				label 	var Dlag_4 ""
				label 	var Dlead_4 ""
				label 	var Dlag_5 ""
					label 	var Dlead_5 ""
				*/				
				label 	var first_name1 "Primeiro nome aluno"
				label 	var first_name2 "Segundo nome aluno"
				label 	var first_name3 "Terceiro nome do aluno"
				label 	var sizename1 "Tamanho do primeiro nome do aluno"
				label 	var sizename2 "Tamanho do segundo nome do aluno"
				label 	var sizename3 "Tamanho do terceiro nome do aluno"
				label 	var id_emprel "ID único da base de dados da Emprel (cada ano e mat tem um id diferente)"	
				*/
				**
			
				compress
				recast str name_student
				save "$dtinter/Emprel.dta", replace
			}

			
			use "$dtinter/Emprel.dta", clear
			
			gen atencao = 1 if t_acelera == 1 & status == 5
			
			bys  cd_mat: egen max_atencao = max(atencao) 
			
			sort cd_mat year
			
			br 	 cd_mat year type_program grade status if max_atencao == 1
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
	/*
	**		
	*ENTENDENDO A IMPLEMENTAÇÃO DO PROGRAMA
	**
	* --------------------------------------------------------------------------------------------------------- *
		
		use "$dtfinal/SE LIGA & Acelera_Recife.dta", clear
		sort cd_mat year
		
			count if  (type_program == 3) & type_program[_n-1] == 1
			*  14,062 alunos que migram para o SLA (estavam na educação regular e passaram para o SLA
					
			count if  (type_program == 3) & type_program[_n-1] == 1 & codschool[_n] == codschool[_n-1]
			*  11,695 desses alunos permanecem na mesma escola, ou seja, a escola formou uma turma para alunos atrasados
					
			count if  (type_program == 3) & type_program[_n-1] == 1 & codschool[_n] != codschool[_n-1]
			*   2,367desses alunos migraram para outra escola para participar do type_program

			codebook codschool												//229 escolas
			codebook codschool if type_program == 2 | type_program == 3		//164 implementaram se liga e acelera
					
			sort  codschool year type_program grade cd_turma dist_1mais dist_2mais 
					
			//no ano em que a escola adotou o se liga e o acelera, todos os alunos foram incluídos? 		
			bys codschool year: gen escola_sla      = (type_program == 2 | type_program == 3)
			bys codschool year: egen max_escola_sla = max(escola_sla)
			
			
			*Nem todas as escolas que implementaram se liga e acelera pegaram todos os alunos com distorção idade-série para participar
			 tab type_program dist_1mais if max_escola_sla == 1 & year == 2010	

				*Qual o programa no qual os alunos com distorção idade-série estão matriculados no ano de 2010 em escolas que adotaram o se liga/acelera
				
			/*	
			   Program |
			student is |      dist_1mais
			  enrolled |        No        Yes |     Total
			-----------+----------------------+----------
			   Regular |    12,959      3,162 |    16,121 
			   Se liga |       136        797 |       933 `'
			   Acelera |        11        235 |       246 
			-----------+----------------------+----------
				 Total |    13,106      4,194 |    17,300 

			*/

			
			*Alguns alunos que estão no se liga ou acelera mas não apresentam distorção idade-série
			
			tab type_program dist_1mais
			
					/*

			   Program |
			student is |      dist_1mais
			  enrolled |        No        Yes |     Total
			-----------+----------------------+----------
			   Regular |   568,050    178,075 |   746,125 
			   Se liga |       666      8,092 |     8,758 
			   Acelera |       359      7,748 |     8,107 
			-----------+----------------------+----------
				 Total |   569,075    193,915 |   762,990 


			*/
					
			bys 	codschool: egen implementou_sla = max(type_program)
			replace implementou_sla = 0 if implementou_sla == 1
			replace implementou_sla = 1 if implementou_sla >  1
			collapse (mean)distorcao, by (year implementou_sla) //a distorção idade-série é maior entre as escolas que implementaram o type_program.
					



				
				
				
			
					*Same school, name of the student, mother's , same year and same birthday, but distinct code of enrollment. 
			*----------------------------------------------------------------------------------------------------------------------------------------------------- *			
			{
			sort year codschool name_student nm_mae 
			count 		 if codschool[_n] == codschool[_n-1] & name_student[_n] == name_student[_n-1] & nm_mae[_n] == nm_mae[_n-1] & year[_n] == year[_n-1] & cd_mat[_n] != cd_mat[_n-1]
			gen erro = 1 if codschool[_n] == codschool[_n-1] & name_student[_n] == name_student[_n-1] & nm_mae[_n] == nm_mae[_n-1] & year[_n] == year[_n-1] & cd_mat[_n] != cd_mat[_n-1]
			bys  	year codschool name_student nm_mae : egen max_erro = max(erro)
			br 		year cd_mat codschool name_student dt_nasc nm_mae grade type_program if max_erro == 1
			bys cd_mat: gen times = _N
			bys cd_mat: egen max_erro2 = max(max_erro)
			br 		year cd_mat codschool times name_student dt_nasc nm_mae grade type_program if max_erro2 == 1
			sort name_student grade year
			drop 	if  times == 1 & max_erro == 1
			drop 		max_erro erro max_erro2 times
			
			sort year codschool name_student nm_mae 
			gen erro = 1 if codschool[_n] == codschool[_n-1] & name_student[_n] == name_student[_n-1] & nm_mae[_n] == nm_mae[_n-1] & year[_n] == year[_n-1] & cd_mat[_n] != cd_mat[_n-1]
			bys  	year codschool name_student nm_mae : egen max_erro = max(erro)
			br 		year cd_mat codschool name_student dt_nasc nm_mae grade type_program if max_erro == 1
			sort name_student grade year
			bys cd_mat: gen times = _N
			bys cd_mat: egen max_erro2 = max(max_erro)
			br 		year cd_mat codschool turma times name_student dt_nasc nm_mae grade type_program status if max_erro2 == 1 // Eu verifiquei caso a casos
			
			drop if cd_mat == 7287712 & year == 2017 & status == 0
			replace cd_mat =  7287712 if cd_mat == 14108224 
			
			drop if cd_mat == 11438614 & year == 2015 & grade ==0
			
			drop if cd_mat == 8014493 & year == 2015 & grade ==3
			
			drop if cd_mat == 3390098
			
			drop if cd_mat == 14012049 & year == 2015 & grade== 4 & status == 5
			replace cd_mat = 10003576 if cd_mat == 14012049
			
			drop if cd_mat == 11758333 & year == 2015 & grade == 2
			
			replace cd_mat = 14137780 if cd_mat == 11758333
			
			drop if cd_mat == 13262181 & year == 2015 & grade == 3 & type_program == 2 
			drop if cd_mat == 7034539
			}
			
			

		
	
	
	
