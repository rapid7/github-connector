ready = ->
  $("span[data-time]").each (i, element) ->
    data = $(element).data()
    if data.time
      date = new Date(data.time)
      timezone = /\((.*)\)/.exec(date.toString())
      if timezone
        formatted_date = date.toLocaleString() + " " + timezone[1]
      else
        formatted_date = date.toString()
      $(element).html(formatted_date)


$(document).ready(ready)
$(document).on('page:load', ready)
