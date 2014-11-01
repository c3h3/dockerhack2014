



@IPyNBs = new Meteor.Collection "ipynb"




Router.configure
  layoutTemplate: 'layout'
    

Meteor.startup ->
  Router.map -> 
    
    @route "index",
      path: "/"
      template: "index"
      data:
        user: ->
          Meteor.user()


    @route "ipynb",
      path: "ipynb/"
      template: "analyzer"
      data:
        name: "ipynb"
        user: ->
          Meteor.user()

        ipynb: ->
          Session.get "ipynb"

        # ipynbUrl: ->
        #   ipynb = Session.get "ipynb"
        #   console.log "ipynb = "
        #   console.log ipynb
        #   url = "http://10.255.252.206:"+ipynb.port+"/tree"
        #   console.log url
        #   url


      waitOn: -> 
        userId = Meteor.userId()
        console.log "userId = "
        console.log userId
        if not userId 
          Router.go "pleaseLogin"

        Meteor.call "getIPyNB", (err, data)->
          if not err
            Session.set "ipynb", data


     @route "rstudio",
      path: "rstudio/"
      template: "analyzer"
      data:
        name: "rstudio"
        user: ->
          Meteor.user()

        ipynb: ->
          Session.get "ipynb"

        # ipynbUrl: ->
        #   ipynb = Session.get "ipynb"
        #   console.log "ipynb = "
        #   console.log ipynb
        #   url = "http://10.255.252.206:"+ipynb.port+"/tree"
        #   console.log url
        #   url


      waitOn: -> 
        userId = Meteor.userId()
        console.log "userId = "
        console.log userId
        if not userId 
          Router.go "pleaseLogin"

        Meteor.call "getRstudio", (err, data)->
          if not err
            Session.set "ipynb", data

    @route "pleaseLogin",
      path: "pleaseLogin/"
      template: "pleaseLogin"



if Meteor.isClient
  Template.shogunIndex.events
    "click .connectBt": (e, t)->
      e.stopPropagation()
      ipynb = Session.get "ipynb"
      url = "http://10.255.252.206:"+ipynb.port
      
      $("#ipynbframe").attr 'src', url
          
  # Template.shogunIndex.rendered = ->
  #   ipynb = Session.get "ipynb"
  #   console.log "ipynb = "
  #   console.log ipynb 
  #   console.log @data.ipynb()



if Meteor.isServer
  @basePort = 8000

  Meteor.publish "ipynb", ->
    userId = Meteor.userId()

    if not userId
      throw new Meteor.Error(401, "You need to login to post new stories")
    
    IPyNBs.findOnd userId:userId 
    


  Meteor.methods
    "getIPyNB": -> 
      user = Meteor.user()
      Docker = Meteor.npmRequire "dockerode"
      docker = new Docker {socketPath: '/var/run/docker.sock'}
      fport = String(basePort + IPyNBs.find().count())

      if IPyNBs.find({userId:user._id, type:"ipynb"}).count() is 0
        console.log "create new ipynb docker"

        ipynbData = 
          userId: user._id
          port: fport
          type: "ipynb"
        
        console.log "ipynbData = "
        console.log ipynbData

        IPyNBs.insert ipynbData

        docker.createContainer {Image: "c3h3/oblas-py278-shogun-ipynb", name:user._id+"_ipynb"}, (err, container) ->
          portBind = 
            "8888/tcp": [{"HostPort": fport}] 
          
          container.start {"PortBindings": portBind}, (err, data) -> 
            console.log "data = "
            console.log data


      else
        console.log "ipynb docker is created"

      # Docker = Meteor.npmRequire "dockerode"
      # docker = new Docker {socketPath: '/var/run/docker.sock'}
      
      # fport = String(basePort + IPyNBs.find().count())

      # if IPyNBs.find({userId:user._id, type:"rstudio"}).count() is 0
      #   console.log "create new ipynb docker"

      #   ipynbData = 
      #     userId: user._id
      #     port: fport
      #     type: "rstudio"
        
      #   console.log "ipynbData = "
      #   console.log ipynbData

      #   IPyNBs.insert ipynbData

      #   docker.createContainer {Image: "rocker/rstudio", name:user._id+"_rstudio"}, (err, container) ->
      #     portBind = 
      #       "8787/tcp": [{"HostPort": fport}] 
          
      #     container.start {"PortBindings": portBind}, (err, data) -> 
      #       console.log "data = "
      #       console.log data


      # else
      #   console.log "ipynb docker is created"


      IPyNBs.findOne {userId:user._id,type: "ipynb"}

    "getRstudio": ->  
      user = Meteor.user()
      Docker = Meteor.npmRequire "dockerode"
      docker = new Docker {socketPath: '/var/run/docker.sock'}
      fport = String(basePort + IPyNBs.find().count())


      if IPyNBs.find({userId:user._id, type:"rstudio"}).count() is 0
        console.log "create new ipynb docker"

        ipynbData = 
          userId: user._id
          port: fport
          type: "rstudio"
        
        console.log "ipynbData = "
        console.log ipynbData

        IPyNBs.insert ipynbData

        docker.createContainer {Image: "rocker/rstudio", name:user._id+"_rstudio"}, (err, container) ->
          portBind = 
            "8787/tcp": [{"HostPort": fport}] 
          
          container.start {"PortBindings": portBind}, (err, data) -> 
            console.log "data = "
            console.log data


      else
        console.log "ipynb docker is created"

      IPyNBs.findOne {userId:user._id,type: "rstudio"}






           




  Accounts.onCreateUser (options, user) ->

    userMeetupId = String(user.services.meetup.id)
    userMeetupToken = user.services.meetup.accessToken

    userProfileUrl = "https://api.meetup.com/2/member/" + userMeetupId + "?&sign=true&photo-host=public&access_token=" + userMeetupToken

    res = Meteor.http.call "GET", userProfileUrl
    
    resData = JSON.parse res.content
    
    user.services.meetup.apiData = {}
    _.extend user.services.meetup.apiData, resData 

    user.profile = {}

    user.profile.name = resData.name
    user.profile.hometown = resData.hometown
    user.profile.photo = resData.photo
    user.profile.link = resData.link
    user.profile.city = resData.city
    user.profile.country = resData.country
    user.profile.joined = resData.joined
    user.profile.topics = resData.topics
    user.profile.other_services = resData.other_services

    user