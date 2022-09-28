                     

						 
																*MASTER DO FILE - SE LIGA E ACELERA EM RECIFE*
	*______________________________________________________________________________________________________________________________________________________________ *
	/*
	Vivian Amorim. vamorim@worldbank.org. vivianamorim5@gmail.com
	*/

	
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	* PART 0:  INSTALL PACKAGES AND STANDARDIZE SETTINGS
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	*Install all packages that this project requires:
	   local user_commands ietoolkit ivreg2 ranktest ritest rsort mediation outreg2 //Fill this list will all user-written commands this project requires
	   foreach command of local user_commands {
		   cap which `command'
		   if _rc == 111 {
			   ssc install `command'
		   }
	   }
	   
	   *Standardize settings accross users
	   ieboilstart, version(15)          //Set the version number to the oldest version used by anyone in the project team
	   `r(version)'                        //This line is needed to actually set the version from the command above
			graph set window fontface "Times"
			set scheme economist 
			set varabbrev off
	
	
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	* PART 1:  PREPARING FOLDER PATH GLOBALS
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *

	   **
	   *User Number:			 
	   * Vivian					 1
	   * User 					 2
	   
	   *Set this value to the user currently using this file
	   global user  1

	   * Root folder globals
	   * ---------------------
		**
		if $user == 1 {
		   global projectfolder     "C:\Users\wb495845\OneDrive\World Bank\I. Education\seliga-acelera-recife\DataWork"
		   global educationdata		"C:\Users\wb495845\OneDrive\Data_analysis"
		   global ideb         		"$educationdata/IDEB/DataWork/Datasets/3. Final"
		   global censoescolar      "$educationdata/Censo Escolar/DataWork/Datasets/3. Final"
		   global rendimento        "$educationdata/Rendimento/DataWork/Datasets/3. Final" 
		   global distorcao 		"$educationdata/Distorção Idade-Série/DataWork/Datasets/3. Final"
		   global dofiles     		"C:\Users\wb495845\OneDrive\World Bank\I. Education\seliga-acelera-recife\DataWork\Do files"
	   }
	   
	   **
	   if $user == 2 {
		   global projectfolder 
		   global dofiles		 
	   }

	   **
	   **
		   global data				"$projectfolder/Datasets"
		   global dtraw				"$data/Raw"
		   global dtinter			"$data/Intermediate" 
		   global dtfinal			"$data/Final"
		   global tables 			"$projectfolder/Output/Tables" 
		   global figures			"$projectfolder/Output/Figures" 
		
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	* PART 2: SET GLOBALS FOR CONSTANTS
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
		
		*do "$dofiles\global_setup.do" 
	   
	   
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	* PART 3: - RUN DOFILES CALLED BY THIS MASTER DOFILE
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *
	* ------------------------------------------------------------------------------------------------------------------------------------------------------------- *

 
                     

