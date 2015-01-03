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
          timeslips = [
            t <- timeslips
            {
              hours = t.timeslip.hours
              projectName = t.project.name
              taskName = t.task.name
            }
          ]
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
              project = {
                name = project.name
                url = project.url
              }
              task = {
                name = task.name
                url = task.url
              }
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
              h 'tr.day' {
                class = {
                  weekend = day.weekend
                  logged  = day.totalHours == 8
                }
              } (
                h 'td.time' (
                  h 'time' (
                    h 'span.day-of-week'  (day.formattedDayOfWeek)
                    h 'span.day-of-month' (day.formattedDayOfMonth)
                    h 'span.month'        (day.formattedMonth)
                  )
                )
                h 'td.timeslips' (
                  h 'table' (
                    day.timeslips.map @(ts)
                      h 'tr.time-display' (
                        h 'td' (
                          parseFloat(ts.hours).toString()
                          ' hours '
                          ts.projectName
                          ' - '
                          ts.taskName
                        )
                      )
                  )

                  if (day.enableEntry)
                    h 'div.time-input' (
                      h 'input.hours' {
                        type = 'text'
                        binding = [day, 'hours']
                      }
                      'hours'
                      h 'select' {
                        binding = [day, 'task']
                      } (
                        model.tasks.map @(t)
                          h 'option' { value = t } (
                            "#(t.project.name) - #(t.task.name)"
                          )
                      )
                      h 'button' { onclick = addTimeslip(day) } 'Add'
                    )
                  else
                    h 'div.time-input.entry-disabled' (
                      h 'a.enable-entry' {
                        href = '#'
                        onclick = enableEntry(day)
                      } '...'
                    )
                )
              )
          )
      )
  }
