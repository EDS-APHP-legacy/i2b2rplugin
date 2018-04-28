library(data.table)
fact_tmp <- fact_tmp[,c("patient_num", "encounter_num", "instance_num",  "provider_id", "location_cd", "start_date", "concept_cd", "observation_blob","sourcesystem_cd")]
setnames(fact_tmp,c("id_patient", "id_visite", "id_fait", "unite_executrice", "unite_responsabilite", "date_validation_doc", "code_doc", "contenu","source"))
fact_tmp$contenu <- iconv(fact_tmp$contenu, from = "UTF-8", to = "latin1" , sub="")
file_name <- "fait_doc"
