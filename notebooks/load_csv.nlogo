extensions [ csv table ]

globals [ params param-cols]

turtles-own [ class ]

to setup 
  ca
  let fpath "weights.csv"
  let csv-rows csv:from-file fpath 
  
  ; Define params as a dictionary
  set params table:make
  
  ; Pull key values as csv header (minus agent column)
  let header-row first csv-rows  
  set param-cols but-first header-row
  
  ; Iterate over the value rows
  foreach but-first csv-rows [ row -> 
    ; Pull current agent class
    let cur-class first row
    
    ; Pull values as csv items (minus agent column)
    let vals but-first row
    
    ; Convert to a keypair list then to a dictionary
    let key-vals ( map [ [ i j ] -> list i j ] param-cols vals )
    let dict table:from-list key-vals
    
    ; Add entry to params
    table:put params cur-class dict
  ]
    
  print params
  reset-ticks
end

to-report class-param [ class_ item_ ] 
   report table:get (table:get params class_) item_
end 

to go 
  print "LI cbd value:"
  print class-param "li" "cbd"
  
  print "Class parameter values sum:"
  foreach [ "dp" "li" "mi" "hi" ] [ cls  -> 
    print word cls ":"
    print sum map [ i -> class-param cls i ] param-cols
  ]  
end