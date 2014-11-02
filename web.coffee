
@rootURL = "0.0.0.0"

@Courses = new Meteor.Collection "courses"

@Dockers = new Meteor.Collection "dockers"

@courseCreator = ["W8ry5vcMNY2GhukHA"]

Router.configure
  layoutTemplate: 'layout'
    

Meteor.startup ->
  Router.map -> 
    
    @route "index",
      path: "/"
      template: "index"
      data:
        rootURL:rootURL
        user: ->
          Meteor.user()

    @route "courses",
      path: "courses/"
      template: "courses"
      data:
        user: ->
          Meteor.user()
        isCreator: ->
          uid = Meteor.userId()
          uid in courseCreator
        courses: ->
          Courses.find()
      waitOn: ->
        userId = Meteor.userId()
        console.log "userId = "
        console.log userId
        if not userId 
          Router.go "pleaseLogin"
        
        Meteor.subscribe "allCourses"

    @route "course",
      path: "course/:cid"
      template: "course"
      data:
        rootURL:rootURL
        user: ->
          Meteor.user()
        course: ->
          cid = Session.get "cid"
          Courses.findOne _id: cid

        hasSlides: ->
          cid = Session.get "cid"
          c = Courses.findOne _id: cid
          console.log "c = "
          console.log c
          console.log cid
          c.slides isnt ""
        docker: ->
          Session.get "docker"


      waitOn: -> 
        userId = Meteor.userId()
        console.log "userId = "
        console.log userId
        if not userId 
          Router.go "pleaseLogin"

        Meteor.subscribe "allCourses"
        Session.set "cid", @params.cid

        Meteor.call "getCourseDocker", @params.cid, (err, data)->
          if not err
            Session.set "docker", data

        

    @route "ipynb",
      path: "ipynb/"
      template: "analyzer"
      data:
        rootURL:rootURL
        baseImageUrl: "https://registry.hub.docker.com/u/c3h3/oblas-py278-shogun-ipynb/"
        name: "ipynb"
        user: ->
          Meteor.user()

        docker: ->
          Session.get "docker"


      waitOn: -> 
        userId = Meteor.userId()
        console.log "userId = "
        console.log userId
        if not userId 
          Router.go "pleaseLogin"

        Meteor.call "getDockers", "c3h3/oblas-py278-shogun-ipynb", (err, data)->
          if not err
            Session.set "docker", data

        # Meteor.call "updateDockers"


     @route "rstudio",
      path: "rstudio/"
      template: "analyzer"
      data:
        rootURL:rootURL
        baseImageUrl: "https://registry.hub.docker.com/u/rocker/rstudio/"
        name: "rstudio"
        user: ->
          Meteor.user()

        docker: ->
          Session.get "docker"

      waitOn: -> 
        userId = Meteor.userId()
        console.log "userId = "
        console.log userId
        if not userId 
          Router.go "pleaseLogin"

        Meteor.call "getDockers", "rocker/rstudio", (err, data)->
          if not err
            Session.set "docker", data

        # Meteor.call "updateDockers"

    @route "pleaseLogin",
      path: "pleaseLogin/"
      template: "pleaseLogin"



if Meteor.isClient
  # Template.course.events
  #   "click .connectBt": (e, t)->
  #     e.stopPropagation()
  #     docker = Session.get "docker"
  #     url = "http://"+rootURL+":"+docker.port
      
  #     $("#docker").attr 'src', url


  # Template.analyzer.events
  #   "click .connectBt": (e, t)->
  #     e.stopPropagation()
  #     docker = Session.get "docker"
  #     url = "http://"+rootURL+":"+docker.port
      
  #     $("#docker").attr 'src', url

  Template.courses.events
    "click input.createBt": (e,t) ->
      e.stopPropagation()
      data =
        courseName: $("input.courseName").val()
        dockerImage: $("input.dockerImage").val()
        slides: $("input.slides").val()
        description: $("input.description").val()
      
      Meteor.call "createCourse", data



          
  # Template.shogunIndex.rendered = ->
  #   ipynb = Session.get "ipynb"
  #   console.log "ipynb = "
  #   console.log ipynb 
  #   console.log @data.ipynb()



if Meteor.isServer
  @basePort = 8000
  @allowImages = ["c3h3/oblas-py278-shogun-ipynb", "c3h3/learning-shogun", "rocker/rstudio", "c3h3/dsc2014tutorial"]
  

  Meteor.publish "dockers", ->
    userId = Meteor.userId()

    if not userId
      throw new Meteor.Error(401, "You need to login")
    
    Dockers.findOnd userId:userId 
    
  Meteor.publish "allCourses", ->
    Courses.find()


  Meteor.methods
    "createCourse": (courseData) ->
      user = Meteor.user()

      if not user
        throw new Meteor.Error(401, "You need to login")
    
      courseData["creator"] = user._id
      courseData["creatorName"] = user.profile.name
      courseData["creatorAt"] = new Date

      Courses.insert courseData
    
    # "updateDockers": ->
    #   Docker = Meteor.npmRequire "dockerode"
    #   docker = new Docker {socketPath: '/var/run/docker.sock'}
    #   docker.listContainers all: false, (err, containers) ->  
    #     for c in containers
    #       console.log "c = "
    #       console.log c
    #       Dockers.update {name:c.Names[0].replace("/","")}, {$set:{containerId:c.Id}} 


    "getDockers": (baseImage) -> 
      user = Meteor.user()
      if not user
        throw new Meteor.Error(401, "You need to login")

      if baseImage not in allowImages
        throw new Meteor.Error(402, "Image is not allow")  

      Docker = Meteor.npmRequire "dockerode"
      docker = new Docker {socketPath: '/var/run/docker.sock'}
      fport = String(basePort + Dockers.find().count())

      if baseImage is "c3h3/oblas-py278-shogun-ipynb"
        imageTag = "ipynb"
      else if baseImage is "rocker/rstudio"
        imageTag = "rstudio"
      else if baseImage is "c3h3/learning-shogun"
        imageTag = "shogun"
      else if baseImage is "c3h3/dsc2014tutorial"
        imageTag = "dsc2014tutorial"

      dockerData = 
        userId: user._id
        port: fport
        baseImage: baseImage
        name:user._id+"_"+imageTag

      console.log "dockerData = "
      console.log dockerData

      dockerQuery = 
        userId:dockerData.userId
        baseImage:dockerData.baseImage

      if Dockers.find(dockerQuery).count() is 0
        console.log "create new docker instance"

        Dockers.insert dockerData

        docker.createContainer {Image: dockerData.baseImage, name:dockerData.name}, (err, container) ->
          if imageTag in ["ipynb","shogun"]
            portBind = 
              "8888/tcp": [{"HostPort": fport}] 
          else if imageTag in ["rstudio", "dsc2014tutorial"]
            portBind = 
              "8787/tcp": [{"HostPort": fport}] 
          
            
          container.start {"PortBindings": portBind}, (err, data) -> 
            console.log "data = "
            console.log data


      else
        console.log "docker is created"

      Dockers.findOne dockerQuery

    "getCourseDocker": (courseId) -> 
      user = Meteor.user()
      if not user
        throw new Meteor.Error(401, "You need to login")

      course = Courses.findOne _id:courseId


      Docker = Meteor.npmRequire "dockerode"
      docker = new Docker {socketPath: '/var/run/docker.sock'}
      fport = String(basePort + Dockers.find().count())

      baseImage = course.dockerImage
      

      if baseImage not in allowImages
        throw new Meteor.Error(402, "Image is not allow")  

      if baseImage is "c3h3/oblas-py278-shogun-ipynb"
        imageTag = "ipynb"
      else if baseImage is "rocker/rstudio"
        imageTag = "rstudio"
      else if baseImage is "c3h3/learning-shogun"
        imageTag = "shogun"
      else if baseImage is "c3h3/dsc2014tutorial"
        imageTag = "dsc2014tutorial"

      dockerData = 
        userId: user._id
        port: fport
        baseImage: baseImage
        name:user._id+"_"+imageTag

      console.log "dockerData = "
      console.log dockerData

      dockerQuery = 
        userId:dockerData.userId
        baseImage:dockerData.baseImage

      if Dockers.find(dockerQuery).count() is 0
        console.log "create new docker instance"

        Dockers.insert dockerData

        docker.createContainer {Image: dockerData.baseImage, name:dockerData.name}, (err, container) ->
          if imageTag in ["ipynb","shogun"]
            portBind = 
              "8888/tcp": [{"HostPort": fport}] 
          else if imageTag in ["rstudio", "dsc2014tutorial"]
            portBind = 
              "8787/tcp": [{"HostPort": fport}] 
          
            
          container.start {"PortBindings": portBind}, (err, data) -> 
            console.log "data = "
            console.log data


      else
        console.log "docker is created"

      Dockers.findOne dockerQuery

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