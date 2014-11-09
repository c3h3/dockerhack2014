
@rootURL = "0.0.0.0"

@Courses = new Meteor.Collection "courses"

@Dockers = new Meteor.Collection "dockers"
@DockerImages = new Meteor.Collection "dockerImages"
@Roles = new Meteor.Collection "roles"
@Chat = new Meteor.Collection "chat"


@courseCreator = ["W8ry5vcMNY2GhukHA","JESWJnrYeBvB35brZ"]

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

    @route "about",
      path: "about/"
      template: "about"
      data:
        rootURL:rootURL
        user: ->
          Meteor.user()


    @route "howToUse",
      path: "howToUse/"
      template: "howToUse"
      data:
        rootURL:rootURL
        user: ->
          Meteor.user()

    @route "wishFeatures",
      path: "wishFeatures/"
      template: "wishFeatures/"
      data:
        rootURL:rootURL
        user: ->
          Meteor.user()

        chats: ->
          Chat.find {}, {sort: {createAt:-1}}

      waitOn: ->
        userId = Meteor.userId()
        console.log "userId = "
        console.log userId
        if not userId 
          Router.go "pleaseLogin"

        Meteor.subscribe "Chat", "wishFeatures"

        Session.set "courseId", "wishFeatures"

      
    @route "dockers",
      path: "dockers/"
      template: "dockers"
      data:
        rootURL:rootURL
        user: ->
          Meteor.user()

        isAdmin: ->
          Session.get("isAdmin")
      
      waitOn: ->
        Meteor.call "checkIsAdmin", (err, data)->
          if not err
            Session.set "isAdmin", data


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

        docker: ->
          Session.get "docker"

        chats: ->
          Chat.find {}, {sort: {createAt:-1}}


      waitOn: -> 
        userId = Meteor.userId()
        console.log "userId = "
        console.log userId
        if not userId 
          Router.go "pleaseLogin"

        Meteor.subscribe "allCourses"
        Session.set "cid", @params.cid
        Session.set "courseId", @params.cid

        Meteor.call "getCourseDocker", @params.cid, (err, data)->
          if not err
            Session.set "docker", data

        Meteor.subscribe "Chat", @params.cid

        

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

        chats: ->
          Chat.find {}, {sort: {createAt:-1}}


      waitOn: -> 
        userId = Meteor.userId()
        console.log "userId = "
        console.log userId
        if not userId 
          Router.go "pleaseLogin"

        Meteor.call "getDockers", "c3h3/oblas-py278-shogun-ipynb", (err, data)->
          if not err
            Session.set "docker", data

        Meteor.subscribe "Chat", "ipynbBasic"

        Session.set "courseId", "ipynbBasic"



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

        chats: ->
          Chat.find {}, {sort: {createAt:-1}}


      waitOn: -> 
        userId = Meteor.userId()
        console.log "userId = "
        console.log userId
        if not userId 
          Router.go "pleaseLogin"

        Meteor.call "getDockers", "rocker/rstudio", (err, data)->
          if not err
            Session.set "docker", data

        Meteor.subscribe "Chat", "rstudioBasic"

        Session.set "courseId", "rstudioBasic"
        # Meteor.call "updateDockers"

    @route "pleaseLogin",
      path: "pleaseLogin/"
      template: "pleaseLogin"



if Meteor.isClient
  Template.course.events
    "click .connectBt": (e, t)->
      e.stopPropagation()
      $("#docker").attr 'src', ""

      docker = Session.get "docker"
      url = "http://"+rootURL+":"+docker.port
      
      $("#docker").attr 'src', url


  Template.analyzer.events
    "click .connectBt": (e, t)->
      e.stopPropagation()
      $("#docker").attr 'src', ""
      
      docker = Session.get "docker"
      url = "http://"+rootURL+":"+docker.port
      
      $("#docker").attr 'src', url
  
  Template.chatroom.events
    "change .postChatMsg": (e, t)->
      e.stopPropagation()

      courseId = Session.get "courseId"
      msg = $(".postChatMsg").val()

      $(".postChatMsg").val("")

      Meteor.call "postChat", courseId, msg, (err, data) ->
        if not err
          console.log "data = "
          console.log data

      
      



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

  if Roles.find().count() is 0
    Roles.insert {userId:uid, role:"admin"} for uid in courseCreator

  if Chat.find({courseId:"ipynbBasic"}).count() is 0
    Chat.insert {userId:"systemTest",userName:"systemTest",courseId:"ipynbBasic", msg:"Hello, ipynbBasic", createAt:new Date}

  if Chat.find({courseId:"rstudioBasic"}).count() is 0
    Chat.insert {userId:"systemTest",userName:"systemTest",courseId:"rstudioBasic", msg:"Hello, rstudioBasic", createAt:new Date}

  if Chat.find({courseId:"wishFeatures"}).count() is 0
    Chat.insert {userId:"systemTest",userName:"systemTest",courseId:"wishFeatures", msg:"Hello, wishFeatures", createAt:new Date}


  for oneCourse in Courses.find({}, {_id:1}).fetch()
    if Chat.find({courseId:oneCourse._id}).count() is 0
      Chat.insert {userId:"systemTest",userName:"systemTest",courseId:oneCourse._id, msg:"Hello!", createAt:new Date}


  @basePort = 8000
  @allowImages = ["c3h3/oblas-py278-shogun-ipynb", "c3h3/learning-shogun", "rocker/rstudio", "c3h3/dsc2014tutorial","c3h3/livehouse20141105"]
  

  Meteor.publish "dockers", ->
    userId = Meteor.userId()

    if not userId
      throw new Meteor.Error(401, "You need to login")
    
    Dockers.findOnd userId:userId 
    
  Meteor.publish "allCourses", ->
    Courses.find()

  Meteor.publish "Chat", (courseId) -> 
    Chat.find({courseId:courseId}, {sort: {createAt:-1}, limit:20})

  Meteor.methods
    "postChat": (courseId, msg) ->
      user = Meteor.user()
      if not user
        throw new Meteor.Error(401, "You need to login")
      
      if not courseId
        throw new Meteor.Error(501, "Need courseId")

      if not msg
        throw new Meteor.Error(501, "Need msg")

      chatData = 
        userId: user._id
        userName: user.profile.name 
        courseId: courseId 
        msg: msg 
        createAt: new Date

      Chat.insert chatData

    "checkIsAdmin": ->
      user = Meteor.user()
      if not user
        throw new Meteor.Error(401, "You need to login")
    
      Roles.find({userId:user._id}).count() > 0

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
      else if baseImage is "c3h3/livehouse20141105"
        imageTag = "livehouse20141105"

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
          if imageTag in ["ipynb","shogun","livehouse20141105"]
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
      else if baseImage is "c3h3/livehouse20141105"
        imageTag = "livehouse20141105"


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
          if imageTag in ["ipynb","shogun", "livehouse20141105"]
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
