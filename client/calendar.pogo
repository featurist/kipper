moment = require 'moment'
auth = require './auth'
_ = require 'underscore'

module.exports (model, freeagent) =

  model.days = []
  model.projects = []
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
        addProjectsFromTimeslips(timeslips)
        day = {
          weekend = (date.weekday() == 0 @or date.weekday() == 6)
          formattedDayOfWeek = date.format('ddd')
          formattedDayOfMonth = date.format('DD')
          formattedMonth = date.format('MMM')
          date = yyyymmdd
          day = date.format('dddd')
          timeslips = timeslips
          totalHours = timeslips.map(@(t) @{ parseFloat(t.timeslip.hours) }) \
                                .reduce @(a, b) @{ a + b } 0
        }
        day.enableEntry = (day.totalHours < 8) @and (@not day.weekend)
        day.hours = 8
        days.push (day)
        date := date.subtract(1, 'days')

      model.tasks = _.flatten (
        model.projects.map @(project)
          project.tasks.map @(task)
            {
              project = project
              task = task
            }
      )

      for each @(d) in (days)
        d.task = model.tasks.0

      model.days = days
      model.loading = false
      model.user = freeagent._user

  fetchProjects () =
    freeagent.projects().then @(projects)
      model.projects = projects

  fetchCompany () =
    freeagent.company().then @(company)
      model.company = company

  addProjectsFromTimeslips (timeslips) =
    for each @(slip) in (timeslips)
      project = _.find(model.projects, @(p) @{ p.url == slip.project.url })
      if (@not project)
        project := slip.project
        model.projects.push(project)

      project.tasks = project.tasks @or []
      task = _.find(project.tasks, @(t) @{ t.url == slip.task.url })
      if (@not task)
        project.tasks.push(slip.task)

  changedTask (e) =
    if (e.target.value == 'Other...')
      fetchProjects ()!

  enableEntry (day) =
    @(e) @{
      e.preventDefault()
      day.enableEntry = true
    }

  addTimeslip (day) =
    @(e) @{
      freeagent.addTimeslip({
        hours = parseFloat(day.hours).toFixed(1)
        task = day.task.task
        date = day.date
      }).then (fetchTimeslips)
    }

  signOut (e) =
    e.preventDefault ()
    auth.signOut ()

  {
    render (h, model) =
      h 'div.calendar' { onattach = fetchTimeslips } (
        if (model.loading)
          h 'div.loading' 'Loading...'
        else
          h 'table.days' (
            h 'tr.header' (
              h 'td' { colSpan = '2', onattach = fetchCompany } (
                h 'h1' 'Kipper'
                if (model.user)
                  h 'div.user' (
                    h 'span.name' (
                      model.user.first_name
                      ' '
                      model.user.last_name
                    )
                    h 'a' { href = '#', onclick = signOut } 'Sign Out'
                  )
              )
            )
            model.days.map @(day)
              h 'tr.day' { class = {
                weekend = day.weekend
                logged = day.totalHours == 8
              } } (
                h 'td.time' (
                  h 'time' (
                    h 'span.day-of-week'  (day.formattedDayOfWeek)
                    h 'span.day-of-month' (day.formattedDayOfMonth)
                    h 'span.month'        (day.formattedMonth)
                  )
                )
                h 'td.tasks' (
                  h 'table.tasks' (
                    day.timeslips.map @(ts)
                      h 'tr' (
                        h 'td' (
                          parseFloat(ts.timeslip.hours).toString()
                          ' hours '
                          ts.project.name
                          ' - '
                          ts.task.name
                        )
                      )

                    if (day.enableEntry)
                      h 'tr.time-input' (
                        h 'td' (
                          h 'input.hours' {
                            type = 'text'
                            binding = [day, 'hours']
                          }
                          'hours'
                          h 'select' {
                            onchange = changedTask
                            binding = [day, 'task']
                          } (
                            model.tasks.map @(t)
                              h 'option' { value = t } (
                                "#(t.project.name) - #(t.task.name)"
                              )
                          )
                          h 'button' { onclick = addTimeslip(day) } 'Add'
                        )
                      )
                    else
                      h 'tr.time-input' (
                        h 'td' (
                          h 'a.enable-entry' {
                            href = '#'
                            onclick = enableEntry(day)
                          } '...'
                        )
                      )
                  )
                )
              )
          )
      )
  }
