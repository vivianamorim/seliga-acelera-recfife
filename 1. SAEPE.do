	**
	**
	*SAEPE - DESEMPENHO DOS ALUNOS EM PORTUGUÊS E MATEMÁTICA
	* _____________________________________________________________________________________________________________________________________________________________ *

			
	*Socioeconomic		
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	{
		**
		*2011			//2010 and 2013 -> no date of bifth
		**
		import  	delimited using "$dtraw/SAEPE/Socioeconômicos/SOCIO - 2011.csv", delimiter(";") clear
		gen 		year = 2011
		keep 		rp_003 nu_sequencial	
		rename  	rp_003 nasc
		tempfile 	socio_11
		save	   `socio_11'
		
		**
		*2012			
		**
		import  	delimited using "$dtraw/SAEPE/Socioeconômicos/SOCIO - 2012.csv", delimiter(";") clear
		gen 		year = 2011
		keep 		rp_003 nu_sequencial	
		rename  	rp_003 ano_nasc 
		destring 	ano_nasc, replace
		tempfile 	socio_12
		save	   `socio_12'
		//we merge socio_11 and socio_12 with the proficiency dataset in order to get the date of birth of the students
	}	
		
		
	*Proficiency
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
		
		**
		*Harmonizing data from 2010 to 2018
		*
		* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
		{
		forvalues year = 10(1)18 {
		
			foreach subject in LP MT {
			
				**
				**
				if `year' < 14 { 
					
					**
					import 	 delimited using "$dtraw/SAEPE/Proficiência/20`year' - `subject'.csv",  	 delimiter(";") clear
				
					**
					keep 	 nu_sequencial vl_prf_aln_`year' nm_aluno cd_etapa* cd_escola *turno* dc_rede*
					
					**
					if `year' == 10						rename (cd_etapa 		cd_escola dc_turno 		 nm_aluno vl_prf_aln_`year' dc_rede 	  )  				     (grade codschool period name_student prof_`subject' 							 network)
					if `year' == 11						rename (cd_etapa 		cd_escola dc_turno 		 nm_aluno vl_prf_aln_`year' dc_rede       ) 		 		 	 (grade codschool period name_student prof_`subject' 							 network)
					if `year' == 12 | `year'  == 13		rename (cd_etapa_turma  cd_escola dc_turno_turma nm_aluno vl_prf_aln_`year' dc_rede_escola) 				 	 (grade codschool period name_student prof_`subject' 							 network)

					**
					if `year' == 11 | `year'  == 12 	merge 1:1 nu_sequencial using `socio_`year'', nogen 		//para pegar a data de nascimento
					
				}
				
				**
				**
				if `year' > 13 & `year' < 16 {
					**
					import 	 excel 	  using "$dtraw/SAEPE/Proficiência/20`year' - `subject'.xls",  				         clear firstrow
					
					**
					keep 	CD_ETAPA_APLICACAO_TURMA CD_ESCOLA DC_TURNO_TURMA NM_ALUNO VL_PROFICIENCIA_`subject' NU_SEQUENCIAL CD_ALUNO RP_006 DC_REDE_ENSINO_ESCOLA  
					
					**
					rename (CD_ETAPA_APLICACAO_TURMA CD_ESCOLA DC_TURNO_TURMA NM_ALUNO VL_PROFICIENCIA_`subject' NU_SEQUENCIAL CD_ALUNO RP_006 DC_REDE_ENSINO_ESCOLA) 	 (grade codschool period name_student prof_`subject' nu_sequencial cd_aluno nasc network)
					
					**
					destring , replace
					format nu_sequencial %20.0f
				}
				
				**
				**
				if `year' > 15 & `year' < 17 {
					
					**
					import 	 delimited using "$dtraw/SAEPE/Proficiência/20`year' - `subject'.csv",       delimiter(";")  clear  
					
					**
					keep 	 cd_etapa_avaliada_turma  cd_escola dc_turno_turma nm_aluno vl_proficiencia  cd_aluno rp_006 dc_rede_ensino_escola
					
					**
					rename  (cd_etapa_avaliada_turma  cd_escola dc_turno_turma nm_aluno vl_proficiencia  cd_aluno rp_006 dc_rede_ensino_escola) 	 		    		 (grade codschool period name_student prof_`subject' nu_sequencial			nasc network)
					
					**
					duplicates tag nu_sequencial, gen (tag)
					
					**
					drop 	if tag > 0
					drop 	   tag 	
				}
				
				**
				**
				if `year' > 16  {
					
					**
					import 	 delimited using "$dtraw/SAEPE/Proficiência/20`year' - `subject'.csv",       delimiter(";")  clear stringcols(_all)  
					
					**
					drop 	 nu_sequencial
					
					**
					gen 	 nu_sequencial = cd_turma_instituicao + nm_aluno + cd_escola + nm_turma
					
					**
					keep 	 cd_etapa  cd_escola dc_turno_turma nm_aluno vl_proficiencia nu_sequencial rp_006 dc_rede_ensino_escola 
					
					**
					rename  (cd_etapa  cd_escola dc_turno_turma nm_aluno vl_proficiencia 			   rp_006 dc_rede_ensino_escola) 	 		    	 		 		 (grade codschool period name_student prof_`subject' 						nasc network)
					
					**
					destring, replace
					
					**
					duplicates tag nu_sequencial, gen (tag)
					drop 	if tag > 0
					drop 	   tag
				}
				
				**
				**
				if `year' != 14 & `year' != 15 {
					**
					foreach var of varlist prof* {
						replace  `var' = subinstr(`var', ",",".",.)
						destring `var', replace
					}
				}
				tempfile `subject'
				save 	``subject''
			}
			
			**
			*Merging Math and Portuguese
			**
			merge 	1:1 nu_sequencial using  `LP', nogen update
			
			**
			gen 	year = 2000 + `year'   
			drop 	if name_student == ""
			
			**
			if 		`year' > 15 drop nu_sequencial
			tempfile 20`year'
			save    `20`year''
		}
		}
		
		**
		*Appending data from 2010 to 2018
		*
		* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
		{
			clear
			forvalues year = 10(1)18 {
				append using `20`year''
			}	
		}
		
		**
		*Setting up dataset
		*
		* --------------------------------------------------------------------------------------------------------------------------------------------------------- *
		{
			**
			replace 	 name_student  = trim(name_student)
			replace 	 name_student  = subinstr(name_student, "?", "", .)
			split 		 name_student, limit(3) gen(first_name)
			gen 		 sizename1 = length(first_name1)
			gen 		 sizename2 = length(first_name2) 
			gen 		 sizename3 = length(first_name3)
			
			
			**
			gen	   		 dt_nasc   = date(nasc, "DMY")
			format 		 dt_nasc %td	
			drop 		 nasc cd_turno cd_turno_turma cd_etapa_divulgacao_turma
			replace 	 ano_nasc = year(dt_nasc) if ano_nasc == .
			
			**
			replace 	 grade = . if grade == 48
			
			**
			replace      period = "1" if period == "MANHÃ"      | period == "INTERMEDIÁRIO MANHÃ" 
			replace      period = "2" if period == "TARDE" 
			replace      period = "3" if period == "NOITE" 
			replace      period = "4" if period == "INTEGRAL" 
			replace      period = "5" if period == "INDEFINIDO" | period == "INTERMEDIÁRIO"
			destring  	 period, replace
			
			**
			format 		 prof* %5.2fc
			
			**
			label 		 define grade 2 "2{sup:nd} grade" 3 "3{sup:rd} grade" 5 "5{sup:th} grade" 9 "9{sup:th} grade" 12 "3{sup:rd} ano EM"
			label 		 define period 2 "Morning" 		  3 "Afternoon"		  4 "Night"			  1 "Integral" 		   5 "Intermediate"
			label 		 val    grade grade
			label		 val 	period period

			*Performance from 0 to 10
			gen 		 prof_MT_stand = .
			gen 		 prof_LP_stand = .
			forvalues year = 2010(1)2018 {
				foreach grade in 2 3 5 9  {
					foreach subject in MT LP {
						su  	prof_`subject'															if 														 grade == `grade' & year == `year', detail
						replace prof_`subject'_stand = (prof_`subject' - r(min))/(r(max) - r(min)) 		if prof_`subject' >  r(min) & prof_`subject' < r(max) &  grade == `grade' & year == `year' & !missing(prof_`subject')
						replace prof_`subject'_stand = 0												if prof_`subject' == r(min) 						  &  grade == `grade' & year == `year' & !missing(prof_`subject')
						replace prof_`subject'_stand = 1												if prof_`subject' == r(max) 					      &  grade == `grade' & year == `year' & !missing(prof_`subject')
						su 		prof_`subject'_stand													if  													 grade == `grade' & year == `year', detail
						*replace prof_`subject'_stand = (prof_`subject' - r(mean))/r(sd)				if 														 grade == `grade' & year == `year' & !missing(prof_`subject')
					}
				}
			}
			
			**
			*Insufficient performance
			**
			gen 	insuf_mat  = 0 if !missing(prof_MT)
			gen 	insuf_port = 0 if !missing(prof_LP)
			replace insuf_port = 1 if prof_LP < 450 & grade == 2
			replace insuf_port = 1 if prof_LP < 500 & grade == 3
			replace insuf_port = 1 if prof_LP < 175 & grade == 5
			replace insuf_port = 1 if prof_LP < 235 & grade == 9
			replace insuf_mat  = 1 if prof_MT < 500 & grade == 2
			replace insuf_mat  = 1 if prof_MT < 550 & grade == 3
			replace insuf_mat  = 1 if prof_MT < 185 & grade == 5
			replace insuf_mat  = 1 if prof_MT < 245 & grade == 9	
			gen 	insuf 	   = 0 if !missing(prof_LP) & !missing(prof_MT)
			replace insuf      = 1 if  insuf_port == 1 & insuf_mat == 1 	
			
			**
			*Average proficiency in Portuguese and Math
			**
			*gen 		prof = ((prof_LP_stand + prof_MT_stand)/2)*10 if !missing(prof_LP_stand) & !missing(prof_MT_stand)		
			*label 	var prof "Proficiency (0-10)"
			format  	prof*  %4.2fc 
			
			**
			keep 		if network == "MUNICIPAL"
			
			**
			set 		seed 112910
			sort 	    cd_aluno
			
			**
			gen  		id_prof = _n
			
			**
			isid 		id_prof, sort
			
			**
			order 		codschool year network id_prof  nu_sequencial cd_aluno name_student dt_nasc ano_nasc first_name1 first_name2 first_name3 sizename1 sizename2 sizename3 grade period  prof*
			
			//prof -> prof media em portugues e matematica
			//insuf - > desempenho insuficiente em portugues e matematica	
			**
			compress
			recast str name_student
			br id_prof name* grade year codschool
			save 	"$dtinter/Proficiência.dta", replace
		}		
			

			
