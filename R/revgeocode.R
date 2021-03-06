#' Reverse geocode
#'
#' reverse geocodes a lat/lng location using Google or Baidu Maps Geocoding API.  Note that in 
#' most cases by using this function you are agreeing to the Google Maps API Terms 
#' of Service at \url{https://developers.google.com/maps/terms} or the Baidu Maps 
#' API Terms of Use at \url{http://developer.baidu.com/map/law.htm}.
#' 
#' @param latlng a location in latitude/longitude format
#' @param ics the coordinate system of inputing location, including WGS-84, GCJ-02 
#' and BD-09, which are the GCSs of Google Earth, Google Map in China and Baidu 
#' Map, respectively. For location out of China, ics is automatically set to 'WGS-84'
#' and other values are ignored.
#' @param api use Google or Baidu Maps Geocoding API
#' @param key an API key must be provided when calling Baidu Maps Geocoding API. When calling Google Maps Geocoding API, you'd better provide an API key, though it is not necessary.
#' @param output formatted address or formmatted address with address components
#' @param messaging turn messaging on/off. The default value is FALSE.
#' @param time the time interval to revgeocode, in seconds. Default value is zero. 
#' When you revgeocode multiple locations, set a proper time interval to avoid 
#' exceeding usage limits. For details see 
#' \url{https://developers.google.com/maps/documentation/geocoding/usage-limits}
#' @return a data.frame with variables address or detail address components 
#' @author Jun Cai (\email{cai-j12@@mails.tsinghua.edu.cn}), PhD candidate from 
#' Department of Earth System Science, Tsinghua University
#' @details note that the google maps api limits to 2,500 free requests per day and 50 requests per second.
#' @seealso \code{\link{geocode}}, \code{\link{geohost}}.
#' 
#' Google Maps API at \url{https://developers.google.com/maps/documentation/geocoding/} 
#' and Baidu Maps API at \url{http://lbsyun.baidu.com/index.php?title=webapi/guide/webservice-geocoding}
#' @export
#' @examples
#' \dontrun{
#' # reverse geocode Beijing Railway Station
#' revgeocode(c(39.90358, 116.421), ics = 'WGS-84', api = 'google', 
#'            output = 'address')
#' revgeocode(c(39.90498, 116.4272), ics = 'GCJ-02', api = 'google', 
#'            output = 'address', messaging = TRUE)
#' revgeocode(c(39.91103, 116.4337), ics = 'BD-09', api = 'google', 
#'            output = 'addressc')
#' revgeocode(c(39.91103, 116.4337), ics = 'BD-09', api = 'baidu', 
#'            key = 'your baidu maps api key', output = 'address')
#' revgeocode(c(39.90498, 116.4272), ics = 'GCJ-02', api = 'baidu', 
#'            key = 'your baidu maps api key', output = 'address', messaging = TRUE)
#' revgeocode(c(39.90358, 116.421), ics = 'WGS-84', api = 'baidu', 
#'            key = 'your baidu maps api key', output = 'addressc')
#' # reverse geocode multiple locations
#' latlng = data.frame(lat = c(39.99837, 39.98565), lng = c(116.3203, 116.2998))
#' revgeocode(latlng, ics = 'WGS-84', api = 'google', output = 'address')
#' revgeocode(latlng, ics = 'WGS-84', api = 'google', output = 'address', time = 2)
#' }

revgeocode <- function(latlng, ics = c('WGS-84', 'GCJ-02', 'BD-09'), 
                       api = c('google', 'baidu'), key = '', 
                       output = c('address', 'addressc'), messaging = FALSE, 
                       time = 0){
  # check parameters
  stopifnot(class(latlng) %in% c('numeric', 'data.frame'))
  ics <- match.arg(ics)
  api <- match.arg(api)
  stopifnot(is.character(key))
  output <- match.arg(output)
  stopifnot(is.logical(messaging))
  stopifnot(is.numeric(time))
  
  # vectorize for many locations
  if (is.data.frame(latlng)) {
    return(ldply(seq_along(latlng), function(i){ 
      Sys.sleep(time)
      revgeocode(as.numeric(latlng[i, ]), ics = ics, api = api, key = key, 
                 output = output, messaging = messaging) }))
  }
  
  # different google maps api is used based user's location. If user is inside China,
  # ditu.google.cn is used; otherwise maps.google.com is used.
  if (api == 'google') {
    cname <- ip.country()
    if (cname == "CN") {
      api_url <- 'http://ditu.google.cn/maps/api/geocode/json'
    } else{
      api_url <- 'https://maps.googleapis.com/maps/api/geocode/json'
    }
  } else{
    api_url <- 'http://api.map.baidu.com/geocoder/v2/'
  }
  
  # format url
  if (api == 'google') {
    # convert coordinates only in China
    if (!outofChina(latlng[1], latlng[2])) {
      latlng <- conv(latlng[1], latlng[2], from = ics, to = 'GCJ-02')
    } else{
      if (ics != 'WGS-84') {
        message('wrong usage: for location out of China, ics can only be set to "WGS-84"', appendLF = T)
      }
    }
    
    # http://maps.googleapis.com/maps/api/geocode/json?latlng=LAT,LNG
    # &sensor=FALSE&key=API_KEY for outside China
    # http://ditu.google.com/maps/api/geocode/json?latlng=LAT,LNG
    # &sensor=FALSE&key=API_KEY for inside China
    url_string <- paste(api_url, '?latlng=', latlng[1], ',', latlng[2], 
                        '&sensor=false', sep = '')
    if (nchar(key) > 0) {
      url_string <- paste(url_string, '&key=', key, sep = '')
    }
  }
  if (api == 'baidu') {
    # coordinate type lookup table
    code <- c('wgs84ll', 'gcj02ll', 'bd09ll')
    names(code) <- c('WGS-84', 'GCJ-02', 'BD-09')
    coordtype <- code[ics]
    # http://api.map.baidu.com/geocoder/v2/?location=LAT,LNG&coordtype=COORDTYPE
    # &output=json&ak=API_KEY
    url_string <- paste(api_url, '?location=', latlng[1], ',', latlng[2], 
                        '&coordtype=', coordtype, '&output=json&ak=', key, sep = '')
  }
  
  if (messaging) message(paste('calling ', url_string, ' ... ', sep = ''), appendLF = F)
  
  # reverse gecode
  con <- curl(URLencode(url_string))
  rgc <- fromJSON(paste(readLines(con, warn = FALSE), collapse = ''))
  if (messaging) message('done.')  
  close(con)
  
  # reverse geocoding results
  if (api == 'google') {
    # did reverse geocoding fail?
    if (rgc$status != 'OK') {
      warning(paste('reverse geocode failed with status ', gc$status, ', location = "', 
                    latlng[1], ', ', latlng[2], '"', sep = ''), call. = FALSE)
      return(data.frame(address = NA))  
    }
    
    # more than one address found?
    if (length(rgc$results) > 1 && messaging) {
      message(paste('more than one address found for "', latlng[1], ', ', 
                    latlng[2],  '", reverse geocoding first ... ', sep = ''), apppendLF = T)
    }
    
    rgcdf <- with(rgc$results[[1]], {data.frame(address = formatted_address, 
                                                row.names = NULL)})
    for (i in seq_along(rgc$results[[1]]$address_components)) {
      rgcdf <- cbind(rgcdf, rgc$results[[1]]$address_components[[i]]$long_name)
    }
    names(rgcdf) <- c('address', sapply(rgc$results[[1]]$address_components, 
                                        function(l) l$types[1]))
  }
  if (api == 'baidu') {
    # did geocode fail?
    if (rgc$status != 0) {
      warning(paste('geocode failed with status code ', rgc$status, ', location = "', 
                    latlng[1], ', ', latlng[2],  '". see more details in the response code table of Baidu Geocoding API', 
                    sep = ''), call. = FALSE)
      return(data.frame(address = NA))
    }
    
    rgcdf <- with(rgc$result, {
      data.frame(address = formatted_address, 
                 street_number = NULLtoNA(addressComponent['street_number']), 
                 street = NULLtoNA(addressComponent['street']), 
                 district = NULLtoNA(addressComponent['district']), 
                 city = NULLtoNA(addressComponent['city']), 
                 province = NULLtoNA(addressComponent['province']), 
                 row.names = NULL)})
  }
  
  if (output == 'address') return(rgcdf['address'])
  if (output == 'addressc') return(rgcdf)
}