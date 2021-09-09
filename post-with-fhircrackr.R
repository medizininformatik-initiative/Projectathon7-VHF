library("httr")

response <-
  httr::GET(url = 'http://lilly:8080/baseR4/Patient?_id=VHF00003,VHF00002', accept_xml())


response <-
  httr::POST(
    url = 'http://lilly:8080/baseR4/Patient/_search',
    body = list('_id' = "VHF00003,VHF00002", '_format' = "xml"),
    encode = "form",
    verbose()
  )

response <-
  httr::POST(url = 'http://lilly:8080/baseR4/Patient/_search',
             body = '_id=VHF00003,VHF00002&_format=xml',
             encode = "form",
             verbose())

response <-
  httr::POST(
    url = 'http://lilly:8080/baseR4/Patient/_search',
    body = '_id=VHF00003,VHF00002',
    accept_xml(),
    encode = "form",
    verbose()
  )

payload <-
  try(httr::content(response, as = "text", encoding = "UTF-8"), silent = TRUE)
xml <- xml2::read_xml(payload)
xml
