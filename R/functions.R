#' i2b2rplugin
#' 
#' Contains basic fonction to dialog with i2b2 database
#' and data model. Supposed to deal with :
#' - Export data feature (first release)
#' - Statistical visualisation (second release)
#' throught OpenCPU R webservice software calls
#' @name i2b2rplugin
#' @docType package

PATH_CONFIG <-"/app/edsr/appli/R/i2b2rplugin/config/"
NULL_VALUE <- "'[protected]'"
PLUGIN_ACTION_EXPORT <- "export"


#' connect
#' 
#' Connection function to the database
#'
#' @return conn the connection object
#' 
connect <- function(){
	connectionFile <- file.path(PATH_CONFIG, "connectionFile.cfg")
	conn <- RPostgres::dbConnect(RPostgres::Postgres() 
				     ,dbname = getValueFromConfFile(connectionFile,"dbname")
				     ,host = getValueFromConfFile(connectionFile,"host")
				     ,port = getValueFromConfFile(connectionFile,"port")
				     ,user = getValueFromConfFile(connectionFile,"user")
				     ,password = getValueFromConfFile(connectionFile,"password")
				     )
}

#' disconnect
#' 
#' Disconnect function to the database
#'
#' @param conn connection object
#'
disconnect <- function(conn){
	RPostgres::dbDisconnect(conn)
}

#' getValueFromConfFile
#'
#' Reading the connection file 
#' 
#' @param character The read file path
#' @param character pattern The field to read
#' 
#' @return character the value
#' 
getValueFromConfFile <- function(file, pattern){
	gsub(paste0(pattern,"="),"",grep(paste0("^",pattern,"="), scan(file,what="",quiet=T),value=T))
}


#' makePreparedQuery
#'
#' Function for prepared statements
#' 
#' @param conn connection object
#' 
makePreparedQuery <- function(conn) {
	function(statement, ...) {
		options(warn=-1)
		params = list(...)

		rs <- RPostgres::dbSendQuery(conn, statement)
		on.exit(RPostgres::dbClearResult(rs))

		if (length(params) > 0) {
			RPostgres::dbBind(rs, params)
		}
		df <- RPostgres::dbFetch(rs, n = -1, ...)
		if (!RPostgres::dbHasCompleted(rs)) {
			RPostgres::dbClearResult(rs)
			warning("Pending rows", call. = FALSE)
		}

		options(warn=0)
		df
	}
}

#' verifParameterFilled
#'
#' Checks if project ID is valiad
#'
#' @param list parameters
#'
#'
verifParameterFilled <- function(parameters){
	params_empty <- c()
	for(i in  1:length(parameters)){
		if(is.na(parameters[i])){
			params_empty <- c(params_empty, names(parameters[i]))
		}
	}
	if(length(params_empty) > 0)
		stop(sprintf("Please fill parameters : %s",paste0(params_empty,collapse=" ; ")), call. = FALSE)
}

#' verifIdProject
#'
#' Checks if project ID is valid
#'
#' @param conn connection object
#' @param idProjet L'idProjet a verifier
#'
#'
verifIdProject <- function(conn, idProject){
	query <- "
	SELECT 1
	FROM i2b2pm.pm_project_data
	WHERE project_id = ($1::varchar)
	AND status_cd = 'A';"

	verifId <- makePreparedQuery(conn)
	verifId(query, idProject)
	r <- nrow(verifId(query,idProject)) > 0
	if(!r)
		stop("Invalid project", call. = FALSE)
}


#' verifIdResult
#'
#' Checks if result ID is valid
#'
#' @param conn connection object
#' @param idResult Result ID
#'
verifIdResult <- function(conn, idResult){
	query <- "
	SELECT 1
	FROM %s.qt_query_result_instance
	WHERE result_instance_id = ($1::numeric)"
	query <- sprintf(query, i2b2DataSchema)

	verifResult <- makePreparedQuery(conn)
	verifResult(query,idResult)
	r <- nrow(verifResult(query,idResult)) > 0
	if(!r)
		stop("Invalid resultset", call. = FALSE)
}




#' getSetTableFromIdResult
#' 
#' This function get the table name to ask for data extraction
#'
#' @param conn connection object
#' @param numeric idResult Result ID
#'
#' @return character The tableset name
#' 
getSetTableFromIdResult <- function(conn, idResult){
	query <- "
	SELECT CASE y.name 
	WHEN 'PATIENTSET' THEN 'qt_patient_set_collection'
	WHEN 'PATIENT_ENCOUNTER_SET' THEN 'qt_patient_enc_collection'
	END as set_table
	FROM %s.qt_query_result_instance x
	LEFT JOIN %s.qt_query_result_type y USING (result_type_id)
	WHERE x.result_instance_id = ($1::numeric);"
	query <- sprintf(query , i2b2DataSchema, i2b2DataSchema)

	quizTable <- makePreparedQuery(conn)
	return( quizTable(query, idResult)$set_table )
}


#' verifActiveSession
#' 
#' Verifies that the user's session is on
#' 
#' @param conn connection object
#' @param character idProject Project ID
#' @param character idSession Session ID 
#' @param character idUser User ID
#'
verifActiveSession <- function(conn, idProject, idSession, idUser){
	query <- "
	WITH tmp AS ( SELECT DISTINCT y.expired_date 
		     FROM i2b2pm.pm_project_user_roles x
		     LEFT JOIN i2b2pm.pm_user_session y USING (user_id)
		     WHERE y.session_id = ($1::varchar)
		     AND project_id = ($2::varchar)
		     AND x.user_id = ($3::varchar)
		     )
	SELECT 1 
	FROM tmp 
	WHERE tmp.expired_date > NOW();"

	endSessionDate <- makePreparedQuery(conn)
	r <- nrow(endSessionDate(query, idSession, idProject, idUser)) > 0
	if(!r)
		stop("Invalid Session", call. = FALSE)
}



#' verifActifUser
#' 
#' Verifies that the user is active and authorized to export the database
#' 
#' @param conn connection object
#' @param character idSession Session ID 
#' @param character idUser User ID
#'
verifActifUser <- function(conn, idSession, idUser){
	query <-"
	SELECT 1
	FROM i2b2pm.pm_user_data x
	LEFT JOIN i2b2pm.pm_user_session y USING (user_id)
	WHERE y.session_id = ($1::varchar)
	AND x.user_id = ($2::varchar) 
	AND x.status_cd = 'A'"

	userActif <- makePreparedQuery(conn)
	r <- nrow( userActif(query, idSession, idUser)) > 0
	if(!r)
		stop("User inactived", call. = FALSE)
}


#' verifQueryOwner
#' 
#' This function ensures that the current user is the author of the petition.
#' 
#' @param conn connection object
#' @param character idSession Session ID 
#' @param character idProject Project ID
#' @param numeric idResult Result ID
#' @param character idUser User ID
#'
#' 
verifQueryOwner <- function(conn, idSession, idProject, idResult, idUser){
	query <- "
	SELECT 1
	FROM %s.qt_query_master x
	LEFT JOIN %s.qt_query_result_instance y ON (x.query_master_id = y.query_instance_id)
	LEFT JOIN i2b2pm.pm_user_session z ON (x.user_id = z.user_id)
	WHERE z.session_id = ($1::varchar)
	AND y.result_instance_id = ($2::numeric)
	AND x.group_id = ($3::varchar)
	AND x.user_id = ($4::varchar)"
	query <- sprintf(query, i2b2DataSchema, i2b2DataSchema)
	queryOwner <- makePreparedQuery(conn)
	r <- nrow(queryOwner( query, idSession, idResult, idProject, idUser )) > 0
	if(!r)
		stop("User does not own query", call. = FALSE)

}


#' getRole
#' 
#' Determines the user's privileges. Columns to display depend on this privilege.
#' 
#' @param conn connection object
#' @param character idProject Project ID
#' @param character idSession Session ID
#'
#' @return character the roles list
#' 
getRole <- function(conn, idProject, idUser){
	query <- "
	SELECT user_role_cd
	FROM i2b2pm.pm_project_user_roles
	WHERE project_id = ($1::varchar)
	AND user_id = ($2::varchar)
	"
	role <- makePreparedQuery(conn)
	return( role(query, idProject, idUser)$user_role_cd )
}


#' buildColumn
#'
#' builds columns to display for exporting visit data set
#' 
#' @param character the column
#' @param character the prefix table
#'
#' @return character List of columns to export
#' 
buildColumn <- function(column){
	paste0(sprintf("%s AS %s",ifelse(sapply(column$Profile,function(x){any(role%in%x)}),column$Column,NULL_VALUE), column$Column),collapse=",")
}


#' getColumnFile
#' 
#' Reads a file from a directory
#' 
#' @param file Name of CSV file
#' 
#' @return data.frame the columns 
#' 
getColumnFile <- function(file){
	read.csv2(file.path(PATH_CONFIG,file), stringsAsFactors=FALSE)
}


#' generateInStatementFromQt
#' 
#' 
#' 
#' @param file Name of CSV file
#' 
#' @return list with 2 strings, patient & encounter 
#' 
generateInStatementFromQt <- function(conn, idResult){
	selectStmt <- ifelse(identical(set_table,"qt_patient_set_collection"),"patient_num, NULL as encounter_num","patient_num, encounter_num")
	query <- "
	SELECT %s
	FROM %s.%s 
	WHERE result_instance_id = ($1::numeric)
	"
	query <- sprintf(query, selectStmt, i2b2DataSchema, set_table)
	qt <- makePreparedQuery(conn)
	res <- qt(query,idResult)
	if(nrow(res)==0){#case set is empty
		patient_num_stmt <- " FALSE "
		encounter_num_stmt <- ""
	}else if(identical(set_table,"qt_patient_set_collection")){#a patient_set
		patient_num <- res$patient_num
		patient_num_stmt <- sprintf(" patient_num IN (%s) ", paste0(patient_num,collapse=","))
		encounter_num_stmt <- ""
	}else{#an encounter_set
		patient_num <- res$patient_num
		patient_num <- patient_num[!duplicated(patient_num)]
		encounter_num <- res$encounter_num

		patient_num_stmt <- sprintf(" patient_num IN (%s) ", paste0(patient_num, collapse=","))
		encounter_num_stmt <- sprintf(" AND encounter_num IN (%s) ", paste0(encounter_num, collapse=","))
	}

	r <- list(patient_num_stmt, encounter_num_stmt)
	return( r )
}

#' factCollection
#'
#' From the result of the query i2b2, this function returns a list of facts matching.
#' @param conn connection object
#' @param numeric Result number
#'
#' @return data.frame facts results
#' 
factCollection <- function(conn, inStmt){
	fact_cols <- buildColumn(getColumnFile("obsFactColumn.csv"))
	query <- "
	SELECT %s
	FROM %s.observation_fact
	WHERE %s%s"
	query <- sprintf(query, fact_cols, i2b2DataSchema, inStmt[[1]] , inStmt[[2]])
	fact <- makePreparedQuery(conn)
	fact(query)
}


#' encounterCollection
#' 
#' From the result of the query i2b2, this function returns a list of visits matching.
#'
#' @param conn connection object
#' @param numeric Result number
#'
#' @return data.frame encounter results
#'
encounterCollection <- function(conn, inStmt){
	enc_cols <- buildColumn(getColumnFile("encounterColumn.csv"))
	query <- "
	SELECT %s
	FROM %s.visit_dimension
	WHERE %s%s
	"
	query <- sprintf(query, enc_cols , i2b2DataSchema , inStmt[[1]] , inStmt[[2]])
	encounter <- makePreparedQuery(conn)
	encounter(query)
}



#' patientCollection
#' 
#' From the result of the query i2b2, this function returns a list of facts matching.
#'
#' @param conn connection object
#' @param numeric Result number
#'
#' @return data.frame patient results
#' 
patientCollection <- function(conn, inStmt){
	patient_cols <- buildColumn(getColumnFile("patientColumn.csv"))
	query <- "
	SELECT %s
	FROM %s.patient_dimension
	WHERE %s
	"
	query <- sprintf(query, patient_cols, i2b2DataSchema,  inStmt[[1]])
	patient <- makePreparedQuery(conn)
	patient(query)
}


#' conceptDimension
#' 
#' From the result of the query i2b2, this function returns a list of matching patients. 
#'
#' @param conn connection object
#'
#' @return data.frame results
#' 
conceptDimension <- function(conn){
	query <- "
	SELECT p.concept_cd, p.name_char, p.concept_path
	FROM %s.concept_dimension p;"
	query <-		sprintf(query, i2b2DataSchema)
	result <- makePreparedQuery(conn)
	result(query)
}

#' providerDimension
#' 
#' From the result of the query i3b2, this function returns a list of matching patients. 
#'
#' @param conn connection object
#'
#' @return data.frame results
#' 
providerDimension <- function(conn){
	query <- "
	SELECT p.provider_id, p.name_char, p.provider_path
	FROM %s.provider_dimension p;"
	query <-		sprintf(query, i2b2DataSchema)
	result <- makePreparedQuery(conn)
	result(query)
}

#' modifierDimension
#' 
#' From the result of the query i2b2, this function returns a list of matching patients. 
#'
#' @param conn connection object
#'
#' @return data.frame results
#' 
modifierDimension <- function(conn){
	query <- "
	SELECT p.modifier_cd, p.name_char, p.modifier_path
	FROM %s.modifier_dimension p;"
	query <- sprintf(query, i2b2DataSchema)
	result <- makePreparedQuery(conn)
	result(query)
}

#' auditInitiate
#' 
#' From the result of the query i2b2, this function returns a list of matching patients. 
#'
#' @param conn connection object
#'
auditInitiate <- function(conn, idUser, idSession, idProject, idResult, researchGoal, exportType){
	query <- "
	INSERT INTO i2b2pm.pm_rplugin_audit ( user_id, session_id, project_id, result_instance_id, user_role_cd, action, start_date, end_date, parameters, has_status_ok, error_msg ) 
	VALUES 
	( ($1::varchar), ($2::varchar), ($3::varchar), ($4::integer), (NULL::varchar), ($5::varchar), Now(), (NULL::timestamp), ($6::jsonb), (NULL::boolean), (NULL::varchar)) 
	RETURNING rplugin_audit_id;"
	insert <- makePreparedQuery(conn)
	rplugin_audit_id <- insert(query, idUser, idSession, idProject, idResult, PLUGIN_ACTION_EXPORT, jsonlite::toJSON(data.frame("researchGoal" = researchGoal, "exportType"=exportType)))
	return(rplugin_audit_id$rplugin_audit_id)
}

#' auditLogRole
#' 
#' From the result of the query i2b2, this function returns a list of matching patients. 
#'
auditLogRole <- function(conn, rplugin_audit_id, role){
	query <- "
	UPDATE i2b2pm.pm_rplugin_audit SET 
	user_role_cd = ($1::varchar)
	WHERE rplugin_audit_id = ($2::numeric);" 
	insert <- makePreparedQuery(conn)
	insert(query, paste0(role, collapse=";"), rplugin_audit_id)
}

#' auditLogOk
#' 
#' From the result of the query i2b2, this function returns a list of matching patients. 
#'
#' @param conn connection object
#'
auditLogOk<- function(conn, rplugin_audit_id){
	query <- "
	UPDATE i2b2pm.pm_rplugin_audit SET 
	end_date = Now()
	,has_status_ok = TRUE
	WHERE rplugin_audit_id = ($1::numeric);" 
	insert <- makePreparedQuery(conn)
	insert(query, rplugin_audit_id)
}

#' auditLogError
#' 
#' From the result of the query i2b2, this function returns a list of matching patients. 
#'
#' @param conn connection object
#'
auditLogError <- function(conn, rplugin_audit_id, error){
	tryCatch({
		query <- "
		UPDATE i2b2pm.pm_rplugin_audit SET 
		end_date = Now() 
		,has_status_ok = FALSE
		,error_msg = ($1::varchar)
		WHERE rplugin_audit_id = ($2::numeric);" 
		insert <- makePreparedQuery(conn)
		insert(query, error, rplugin_audit_id)
	},error = function(e){},
	finally = {stop(error,  call. = FALSE)}
	)
}

#' exportData
#' 
#' Creates different CSV file
#' 
#' @param data Data type to export
#' @param file Name of CSV file
#'
exportData <- function(data, file){
	zipFiles <<- c(zipFiles, file)
	data <- as.data.frame(lapply(data, function(x){if(class(x)%in%"character"){iconv(x,from="UTF-8", to="latin1",sub="" )}else{ x }}))#solves encoding problems
	write.table(data, file, sep=";", quote=T, na="", fileEncoding="latin1", col.names=T, row.names=F)
}

#' downloadAsCsv
#' 
#' This function creates files by each type of data to export.
#' 
#' @param character idUser User ID
#' @param numeric idResult Result number
#' @param character idProject Projet ID
#' @param character idSession Session ID
#' @param character researchGoal Study goal
#' @param character exportData data type to export 
#' 
#' @export
#'
downloadAsCsv <- function(idUser=NA_integer_, idResult=NA_integer_, idProject=NA_character_, idSession=NA_character_, researchGoal=NA_character_, exportType=NA_character_){
	out <- tryCatch({ 
		conn <<- connect()
		verifParameterFilled(list("idUser"=idUser,"idResult"=idResult,"idProject"=idProject,"idSession"=idSession,"researchGoal"=researchGoal,"exportType"=exportType))
		i2b2DataSchema <<- getValueFromConfFile(file.path(PATH_CONFIG,"connectionFile.cfg"),"i2b2DataSchema")
		rplugin_audit_id <- auditInitiate(conn, idUser,idSession, idProject, idResult, researchGoal, exportType)
		verifIdProject(conn, idProject)
		verifIdResult(conn, idResult)
		verifActiveSession(conn, idProject, idSession, idUser)
		verifActifUser(conn, idSession, idUser)
		verifQueryOwner(conn, idSession, idProject, idResult, idUser)
		role <<- getRole(conn, idProject, idUser)
		auditLogRole(conn, rplugin_audit_id, role)
		set_table <<- getSetTableFromIdResult(conn, idResult)
		inStmt <- generateInStatementFromQt(conn, idResult)
		zipFiles <<- c()

		if(grepl(";1",exportType)){#PAT
			patient <- patientCollection(conn, inStmt)
			patient_modify_source <- file.path(PATH_CONFIG,"patient_dimension_modify.R")
			file_name <- "patient_dimension"
			if(file.exists(patient_modify_source)){ source(patient_modify_source, local=TRUE) }
			exportData(patient, file = sprintf("%s.csv", file_name))
			rm(patient)
		}

		if(grepl(";2",exportType)){#ENC
			encounter <- encounterCollection(conn, inStmt)
			encounter_modify_source <- file.path(PATH_CONFIG,"encounter_dimension_modify.R")
			file_name <- "encounter_dimension"
			if(file.exists(encounter_modify_source)){ source(encounter_modify_source, local=TRUE) }
			exportData(encounter, file = sprintf("%s.csv", file_name) )
			rm(encounter)
		}

		if(grepl(";3",exportType)){#OBS
			fact <- factCollection(conn, inStmt)
			factKinds <- unique(sub(":.*$","",unique(fact$concept_cd)))
			for(factKind in factKinds){
				fact_tmp <- fact[grepl(sprintf("^%s",factKind),fact$concept_cd),]
				fact_modify_source <- file.path(PATH_CONFIG,paste0(factKind,"_observation_fact_modify.R"))
				file_name <- sprintf("observation_fact_%s",factKind)
				if(file.exists(fact_modify_source)){ source(fact_modify_source, local=TRUE) }
				exportData(fact_tmp, file = sprintf("%s.csv", file_name) )
				rm(fact_tmp)
			}
		}
		if(grepl(";4",exportType)){#Terminologies
			file_name <- "concept_dimension"
			conceptDim <- conceptDimension(conn)
			concept_modify_source <- file.path(PATH_CONFIG,"concept_dimension_modify.R")
			if(file.exists(concept_modify_source)){ source(concept_modify_source, local=TRUE) }
			exportData(conceptDim, file = sprintf("%s.csv", file_name))

			providerDim <- providerDimension(conn)
			file_name <- "provider_dimension"
			provider_modify_source <- file.path(PATH_CONFIG,"provider_dimension_modify.R")
			if(file.exists(provider_modify_source)){ source(provider_modify_source, local=TRUE) }
			exportData(providerDim, file = sprintf("%s.csv", file_name))

			modifierDim <- modifierDimension(conn)
			file_name <- "modifier_dimension"
			modifier_modify_source <- file.path(PATH_CONFIG,"modifier_dimension_modify.R")
			if(file.exists(modifier_modify_source)){ source(modifier_modify_source, local=TRUE) }
			exportData(modifierDim, file = sprintf("%s.csv", file_name))
		}

		if(grepl(";5",exportType)){#Documentation
			docString <- getValueFromConfFile(file.path(PATH_CONFIG, "connectionFile.cfg"),"documentationFiles")
			docs <- unlist(strsplit(docString,";"))
			for(file in docs){
				system(sprintf('cp "%s%s" .', PATH_CONFIG, gsub(" ","\\ ",file)))
				zipFiles <<- c(zipFiles, file)
			}
		}

		zip(zipfile="export.zip", files=zipFiles)
		auditLogOk(conn, rplugin_audit_id) 
	},error = function(err){
		auditLogError(conn, rplugin_audit_id, err)
	}, finally={
		disconnect(conn)
	})
}
