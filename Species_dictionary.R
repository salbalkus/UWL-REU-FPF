##### This script will serve entirely as a species dictionary, where you can input the species code and it will return the species full name
# This could be useful when making inline statements in an Rmd report


species_dict = list(
  'ACNE2' = 'boxelder',
  'ACSA2' = 'silver maple',
  'BENI' = 'river birch',
  'CACO15' = 'bitternut hickory',
  'CEOC' = 'common hackberry',
  'FRNI' = 'black ash',
  'FRPE' = 'green ash',
  'JUNI' = 'black walnut',
  'PIRE' = 'red pine',
  'PODE3' = 'cottonwood',
  'PRSE3' = 'black cherry',
  'QUBI' = 'swamp white oak',
  'QUEL' = 'northern pin oak',
  'QUMA2' = 'bur oak',
  'QURU' = 'northern red oak',
  'QUVE' = 'black oak',
  'ROPS' = 'black locust',
  'SANI' = 'black willow',
  'TIAM' = 'american basswood',
  'ULAM' = 'american elm',
  'ACSA3' = 'sugar maple',
  'AEGL' = 'ohio buckeye',
  'BEPA' = 'white birch',
  'CAIL2' = 'northern pecan',
  'CALA21' = 'shellback hickory',
  'CAOV2' = 'shagbark hickory',
  'CARYA' = 'hickory spp.',
  'CAAL27' = 'mockernut hickory',
  'CABI8' = 'southern catalpa',
  'CASP8' = 'northern catalpa',
  'CELA' = 'sugarberry',
  'CECA4' = 'easturn redbud',
  'CRATA' = 'hawthorn spp.',
  'DIVI5' = 'common persimmon',
  'FRAM2' = 'white ash',
  'GLTR' = 'honey locust',
  'GYDI' = 'kentucky coffeetree',
  'JUCI' = 'butternut',
  'JUVI' = 'eastern redcedar',
  'LIST2' = 'sweetgum',
  'MAPO' = 'osage orange',
  'MOAL' = 'white mulberry',
  'MORU2' = 'red mulberry',
  'OSVI' = 'ironwood',
  'PIST' = 'eastern white pine',
  'PLOC' = 'sycamore',
  'POGR4' = 'bigtooth aspen',
  'POTR5' = 'quaking aspen',
  'QUAL' = 'white oak',
  'QULY' = 'overcup oak',
  'QUMU' = 'chinkapin oak',
  'QUPA2' = 'pin oak',
  'SAAM2' = 'peachleaf willow',
  'SALIX' = 'willow spp.',
  'TADI2' = 'bald cypress',
  'ULPU' = 'siberian elm',
  'ULRU' = 'red/slippery elm',
  'NONE' = 'none',
  'OTHER' = 'other',
  'SNAG' = 'snag',
  'UNKNOWN' = 'unknown',
  'ALIN2' = 'gray alder',
  'AMFR' = 'false indigobush',
  'CEOC2' = 'common buttonbush',
  'COAM2' = 'silky dogwood',
  'COFL2' = 'flowering dogwood',
  'CORA6' = 'gray dogwood',
  'COSE16' = 'redosier dogwood',
  'CORNU' = 'dogwood spp.',
  'FOAC' = 'swamp privet',
  'FRAL4' = 'glossy buckthorn',
  'ILDE' = 'possumhaw',
  'ILVE' = 'winterberry',
  'LOMA6' = 'amur honeysuckle',
  'LONICER' = 'honeysuckle',
  'PRVI' = 'chockecherry',
  'RHCA3' = 'buckthorn',
  'RHTY' = 'staghorn sumac',
  'SAIN3' = 'sandbar willow',
  'SAMBU' = 'elderberry',
  'STTR' = 'american bladdernut',
  'VILE' = 'nannyberry',
  'XAAM' = 'prickly ash',
  'CATO6' = 'mockernut hickory',
  'QUPA' = 'pin oak'
)

read_dict <- function(species, list_output = T, caps = T){

  CapStr <- function(y) {
    c <- strsplit(y, " ")[[1]]
    paste(toupper(substring(c, 1,1)), substring(c, 2),
          sep="", collapse=" ")
  }
  
  fun <- function(x){
    s <- species_dict[[x]]
    
    if (is.null(s)) s <- x
    
    return(s)
  }
  
  full_sp <- sapply(species, fun)
   
  if (caps){
    full_sp <- sapply(full_sp, CapStr)
  }
  
  if (!list_output){
    last_sp <- full_sp[length(species)]
    full_sp <- c(full_sp[-length(species)], paste('and', last_sp))
  }
  
  return(full_sp)  
}

read_dict('asd')
