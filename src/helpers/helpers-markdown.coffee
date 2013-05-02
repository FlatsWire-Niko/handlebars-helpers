module.exports.register = (Handlebars, options) ->
  fs    = require 'fs'
  path  = require 'path'
  yaml  = require 'js-yaml'
  grunt = require 'grunt'
  file  = grunt.file
  _     = require 'lodash'
  Utils = require '../utils/utils'



  opts = (
    gfm: true
    tables: true
    breaks: false
    highlight: null
    pedantic: false
    sanitize: true
    silent: false
    smartLists: true
    langPrefix: "lang-"
    highlight: (code, lang) ->
      res = undefined
      return code  unless lang
      switch lang
        when "js"
          lang = "javascript"
      try
        res = hljs.highlight(lang, code).value
      finally
        return res or code
  )

  opts     = _.extend opts, options
  markdown = require('../utils/markdown').Markdown opts
  isServer = (typeof process isnt 'undefined')

  ###
  Travis CI: 
  Syntax: {{travis [src]}}
  ###
  Handlebars.registerHelper "travis", (pkg) ->
    travis = "./.travis.yml"
    source = undefined
    template = undefined
    if grunt.file.exists(travis)
      pkg = Utils.readJSON("./package.json")
    else if pkg
      pkg = Utils.readJSON(pkg)
    source = "# [{{ name }} v{{ version }}]({{ homepage }})[![Build Status](https://travis-ci.org/{{ author.name }}/{{ name }}.png)](https://travis-ci.org/{{ author.name }}/{{ name }})"
    template = Handlebars.compile(source)
    Utils.safeString(template(pkg))

  ###
  Authors: reads in data from an "AUTHORS" file to generate markdown formtted
  author or list of authors for a README.md. Accepts a second optional
  parameter to a different file than the default.
  Usage: {{authors}} or {{ authors [file] }}
  ###
  Handlebars.registerHelper 'authors', (authors) ->
    source = undefined
    template = undefined
    if Utils.isUndefined(authors)
      authors = Utils.read("./AUTHORS")
    else
      authors = Utils.read(authors)
    matches = authors.replace(/(.*?)\s*\((.*)\)/g, '* [$1]($2)  ') or []
    Utils.safeString(matches)

  ###
  AUTHORS: (case senstitive) Same as `{{authors}}`, but outputs a different format.
  ###
  Handlebars.registerHelper 'AUTHORS', (authors) ->
    source = undefined
    template = undefined
    if Utils.isUndefined(authors)
      authors = Utils.read("./AUTHORS")
    else
      authors = Utils.read(authors)
    matches = authors.replace(/(.*?)\s*\((.*)\)/g, '\n**[$1]**\n  \n+ [$2]($2)  ') or [] 
    Utils.safeString(matches)


  ###
  Changelog: Reads in data from an "CHANGELOG" file to generate markdown formatted
  changelog or list of changelog entries for a README.md. Accepts a
  second optional parameter to change to a different file than the default.
  Usage: {{changelog}} or {{changelog [src]}}
  ###
  Handlebars.registerHelper "changelog", (changelog) ->
    source = undefined
    template = undefined
    if Utils.isUndefined(changelog)
      changelog = Utils.readYAML('./CHANGELOG')
    else
      changelog = Utils.readYAML(changelog)
    source = "{{#each .}}* {{date}}\t\t\t{{{@key}}}\t\t\t{{#each changes}}{{{.}}}{{/each}}\n{{/each}}"
    template = Handlebars.compile(source)
    Utils.safeString(template(changelog))

  ###
  Roadmap: Reads in data from an "ROADMAP" file to generate markdown formatted
  roadmap or list of roadmap entries for a README.md. Accepts a
  second optional parameter to change to a different file than the default.
  Usage: {{roadmap}} or {{roadmap [src]}}
  ###
  Handlebars.registerHelper "roadmap", (roadmap) ->
    source = undefined
    template = undefined
    if Utils.isUndefined(roadmap)
      roadmap = Utils.readYAML('./ROADMAP')
    else
      roadmap = Utils.readYAML(roadmap)
    source = "{{#each .}}* {{eta}}\t\t\t{{{@key}}}\t\t\t{{#each goals}}{{{.}}}{{/each}}\n{{else}}_(Big plans in the works)_{{/each}}"
    template = Handlebars.compile(source)
    Utils.safeString(template(roadmap))

  ###
  chapter: reads in data from a markdown file, and uses the first heading
  as a chapter heading, and then copies the rest of the content inline.
  Usage: {{ chapter [file] }}
  ###
  Handlebars.registerHelper 'chapter', (file) ->
    file = grunt.file.read(file)
    content = file.replace(/(^[^ ]*\s)(.+)([^#]+(?=.*)$)/gim, '$2\n' + '$3') or []
    Utils.safeString(content)


  ###
  Glob: reads in data from a markdown file, and uses the first heading
  as a section heading, and then copies the rest of the content inline.
  Usage: {{{ glob [file] }}
  ###
  Handlebars.registerHelper 'glob', (file) ->
    file    = file.match(file)
    content = grunt.file.read(file)
    content = content.replace(/(^[^ ]*\s)(.+)([^#]+(?=.*)$)/gim, '$2\n' + '$3') or []
    Utils.safeString(content)

  ###
  Embed: Embeds code from an external file as preformatted text. The first parameter
  requires a path to the file you want to embed. There second second optional
  parameter is for specifying (forcing) syntax highlighting for language of choice.
  Syntax:  {{ embed [file] [lang] }}
  Usage: {{embed 'path/to/file.js'}} or {{embed 'path/to/file.hbs' 'html'}}
  ###
  Handlebars.registerHelper 'embed', (file, language) ->
    file = grunt.file.read(file)
    language = ""  if Utils.isUndefined(language)
    result = '``` ' + language + '\n' + file + '\n```'
    Utils.safeString(result)

  ###
  Markdown: markdown helper enables writing markdown inside HTML 
  and then renders the markdown as HTML inline with the rest of the page.
  Usage: {{#markdown}} # This is a title. {{/markdown}}
  Renders to: <h1>This is a title </h1>
  ###
  Handlebars.registerHelper "markdown", (options) ->
    content = options.fn(this)
    markdown.convert(content)

  if isServer

    ###
    Markdown helper used to read in a file and inject
    the rendered markdown into the HTML.
    Usage: {{md ../path/to/file.md}}
    ###
    Handlebars.registerHelper "md", (path) ->
      content = Utils.read(path)
      tmpl = Handlebars.compile(content)
      md = tmpl(this)
      html = markdown.convert(md)
      Utils.safeString(html)

  @
