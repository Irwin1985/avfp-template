// jsondbClient
// JSONDB JS Client
//
// Author: Victor Espina
// Date: Jun 2014
//
// Copyright NOI Quality Software
//
//
//
var jsondb = new jsondbClient();

function jsondbClient(url, repository)
{
  this.url = url;
  this.repository = repository;
  this.version = "1.0";


  // connect
  //
  this.connect = function(repository, url) {
   if (!url) url = this.url;
   var o = new jsondbClient(url, repository);

   return o;
  }
  
  
  // configure
  //
  this.configure = function(connType, connString, callback) {
    if (!connString) connString = "";
    var request = {
      action: "configure",
      repository: null,
      data: {
        connectionType: connType,
        dbfFolder: connString,
        odbcConnString: connString
      }
    }
    this.sendRequest(request, callback);
  }
  
  
  // configuration
  //
  this.configuration = function(callback) {
    var request = {
      action: "configuration",
      repository: null,
      data: null
    }
    this.sendRequest(request, callback);
  }
  
  
  // createRepository
  //
  this.createRepository = function(callback) {
    var request = {
      action: "create",
      repository: this.repository,
      data: null
    }
    this.sendRequest(request, callback);
  }
  
  
  // isRepository
  //
  this.isRepository = function(callback) {
    var request = {
      action: "info",
      repository: this.repository,
      data: null
    }
    this.sendRequest(request, callback);
  }
  
  
  // dropRepository
  //
  this.dropRepository = function(callback) {
      var request = {
      action: "drop",
      repository: this.repository,
      data: null
    }
    this.sendRequest(request, callback);
  }
  
  
  // listRepositories
  //
  this.listRepositories = function(callback) {
    var request = {
      action: "list",
      repository: null,
      data: null
    }
    this.sendRequest(request, callback);
  }


  // save
  //
  this.save = function(row, callback) {
    var request = {
      action: "save",
      repository: this.repository,
      data: row
    }
    this.sendRequest(request, callback);
  }
  

  // retrieve
  //
  this.retrieve = function(row, orderBy, callback) {

    var request = {
      action: "retrieve",
      repository: this.repository,
      data: {
        parameters: row,
        order: orderBy
      }
    }
    this.sendRequest(request, callback);
  }
  
  
  // delete
  //
  this.delete = function(row, callback) {
    var request = {
      action: "save",
      repository: this.repository,
      data: row
    }
    this.sendRequest(request, callback);
  }
  
  
  
  // sendREquest
  //
  this.sendRequest = function(request, callback) {

    request.url = this.url;
    $.ajax({
             type: "POST",
             url: this.url,
             data: "restdata=" + JSON.stringify(request),
             contentType: "application/x-www-form-urlencoded",
             crossDomain: true,
             dataType: "json",
             cache: false,
             
             success: function (response, status, jqXHR) {
                 response.success = true;
                 response.request = request;
                 response.statusCode = status;
                 if (callback) callback(response);
             },

             error: function (jqXHR, status) {
                 response = {
                  sucess: false,
                  result: false,
                  request: request,
                  status: status,
                  statusCode: jqXHR.status,
                  statusText: jqXHR.statusText,
                  error: jqXHR.responseText
                 };
                 console.log(request);
                 console.log(jqXHR);
                 if (callback) callback(response);
             }
          });
          
  }
}
