moment = require 'moment'
_ = require 'underscore'

module.exports (model, freeagent) =

  model.days = []
  model.loading = true

  fetchTimeslips () =
    freeagent.timeslips().then @(slips)
      dates = _.keys(slips).sort().reverse()
      earliestDate = _.last(dates)
      date = moment().startOf('day')

      days = []
      while (date.format('YYYY-MM-DD') != earliestDate)
        yyyymmdd = date.format('YYYY-MM-DD')
        timeslips = slips.(yyyymmdd) || []
        days.push {
          weekend = (date.weekday() == 0 @or date.weekday() == 6)
          formattedDate = date.format('dddd MMM Do')
          day = date.format('dddd')
          timeslips = timeslips
          totalHours = timeslips.map(@(t) @{ parseFloat(t.timeslip.hours) }) \
                                .reduce @(a, b) @{ a + b } 0
        }
        date := date.subtract(1, 'days')

      model.days = days
      model.loading = false

  {
    render (h, model) =
      h 'div.calendar' { onattach = fetchTimeslips } (
        if (model.loading)
          h 'div' 'loading...'
        else
          h 'ul' (
            model.days.map @(day)
              h 'li' { class = {
                day = true
                weekend = day.weekend
                logged = day.totalHours == 8
              } } (
                h 'h1' (day.formattedDate)
                h 'ul' (
                  day.timeslips.map @(ts)
                    h 'li' (
                      parseFloat(ts.timeslip.hours).toString()
                      ' hours: '
                      ts.project.name
                      ' ('
                      ts.task.name
                      ')'
                    )
                )
              )
          )
      )
  }
