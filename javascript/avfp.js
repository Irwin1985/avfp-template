/*
   avfp.js
   ActiveVFP JS Helper Class
   
   Author: V. Espina
   Date: Jul 2014

*/

// "Static" accesor
var avfp = new avfpHelper();



// avfpHelper (Class)
// ActiveVFP Helper Class
//
function avfpHelper() {
  
  this.debugMode = false;
  this.modal = null;
  this.callbacks = {
    bsmodal: null
  };

  this.bs = new avfpBootstrapHelper();
  this.jqm = new avfpJqueryMobileHelper();


  // preventDefault (Method)
  // Cross-browser preventDefault implementation
  //
  this.preventDefault = function(e) {
    if (!e) return;
    if (e.preventDefault) { // Supported
      e.preventDefault();
    } else {
      e.returnValue = false;  // For IE 10+
    }
  }


  // mergeObjects (Method)
  // Merges the contents of two given objects
  //
  this.mergeObjects = function(obj1, obj2) {
    var result = obj1;
    for (p in obj2) {
      if (jQuery.type(obj2[p]) != "object") {  // If element is not an object, merge it at once
        result[p] = obj2[p];
      } else if (!result.hasOwnProperty(p)) {                 // If element is an object but doesn't exists in the original object, add it
        result[p] = obj2[p];  
      } else {                                 // Merge new object with existing object
        result[p] = this.mergeObjects(result[p], obj2[p]);
      } 
    }
    return result;
  }


  // fillObject (method)
  // Complets an object with a given master-default one
  //
  this.fillObject = function(target, master) {
    for (p in master) {
      if (!target.hasOwnProperty(p)) {
        target[p] = master[p];
      }
    }
    return target;
  }



  // clone (Method)
  // Clone an object
  //
  // options:
  // recursive: true | false
  // exclude: []
  //
  this.clone = function(obj, options) {
    var clone = null;
    options = options || {};
    options.recursive = options.recursive || true;
    options.exclude = options.exclude || [];

    if (arguments.length == 0 || !obj) return clone;
    
    if (obj.constructor == Array) { 

      clone = [];
      for (var i = 0; i < obj.length; i++) {
        var item = obj[i];
        if (typeof item == "object") {
          clone.push(this.clone(item, options));
        } else {
          clone.push(item);
        }
      }

    } else {

      clone = {};
      for (key in obj) {
        var value = obj[key];
        if (options.exclude.length == 0 || options.exclude.indexOf(key) < 0)
          if (typeof value == "object" && options.recursive) {
            clone[key] = this.clone(value);
          } else {
            clone[key] = value;
          }
      }

    }
    return clone;
  }




  // restCall
  // Makes a REST call  
  //
  this.restCall = function(url, method, data, callback) { 
    
    var request = null;
    if (typeof url == "object") {
      request = this.newHttpRequest(url);
    } else {
      request = this.newHttpRequest(url, method, data);
      request.callback = callback;
    }
    this.httpRequest(request, request.callback);
    
  }
  
  
  
  
  // newHttpRequest (Method)
  // Returns a request object to be used with
  // httpRequest method
  //
  this.newHttpRequest = function(url, method, data) {
  
    var options = (typeof url == "object") ? url : {url: url, method: method, data: data};
    var request = {
      url: options.url || "",
      method: options.method || "GET",
      data: options.data || null,
      dataType: options.dataType || "json",
      contentType: options.contentType || "application/x-www-form-urlencoded",
      callback: options.callback || null
    }
    
    return request;
  }
  
 
  // httpRequest
  // Send a HTTP request to the server. The request object 
  // should have the following attrs:
  //
  // url: resource to be requested
  // data: data to be sent
  // dataType: data type (defaults to "json")
  // method: request method (defaults to "GET")
  // 
  this.httpRequest = function(request, callback) {
  
    var dataType = ((request.dataType) ? request.dataType : "text");
    var data = (request.data) ? "restdata=" + escape(JSON.stringify(request.data)) : "";

    $.ajax({
             type: ((request.method) ? request.method : "GET"),
             url: request.url,
             data: data,
             async: true,
             contentType: ((request.contentType) ? request.contentType : "application/x-www-form-urlencoded"),
             crossDomain: true,
             dataType: dataType,
             cache: false,
             
             success: function (result, status, jqXHR) {
                 var response = {
                  success: true,
                  request: request,
                  statusCode: status,
                  data: result
                 }

                 if (callback) callback(response);
             },

             error: function (jqXHR, status) {
                 var response = {
                  sucess: false,
                  request: request,
                  status: status,
                  statusCode: jqXHR.status,
                  statusText: jqXHR.statusText,
                  error: jqXHR.responseText
                 };
                 if (avfp.debugMode && false) {
                   console.log(request);
                   console.log(jqXHR);
                   console.log(jqXHR.getAllResponseHeaders());
                 }
                 if (callback) callback(response);
             }
          });

  }
 


  // restParams
  // Returns a REST call params string
  //
  this.restParams = function() {
    var result = "";
    if (arguments.length == 0) return result;

    for (i=0; i<arguments.length; i++) {
      result = result + ((i > 0) ? "/" : "") + arguments[i];
    }

    return result;
  } 



  // modal (object)
  // Access to the bootstrap modal dialog
  //
  this.modal = new avfpModal();



  // getFormData (Method)
  // Returns an object with the current value of all input elements
  // in the given container.
  //
  this.getFormData = function(selector) {
    var formData = {};
    $(selector + " *").each(function() {
      if (this.name) {
        formData[this.name] = this.value;
      } 
    });

    return formData;
  }


  // xml2json (Method)
  // Generates a JSON representation of a XML document
  //
  this.xml2json = function(xml) {
    try {
      var obj = {};
      if (xml.children.length > 0) {
        for (var i = 0; i < xml.children.length; i++) {
          var item = xml.children.item(i);
          var nodeName = item.nodeName;

          if (typeof (obj[nodeName]) == "undefined") {
            obj[nodeName] = avfp.xml2json(item);
          } else {
            if (typeof (obj[nodeName].push) == "undefined") {
              var old = obj[nodeName];

              obj[nodeName] = [];
              obj[nodeName].push(old);
            }
            obj[nodeName].push(avfp.xml2json(item));
          }
        }
      } else {
        obj = xml.textContent;
      }
      return obj;
    } catch (e) {
        console.log(e.message);
    }
  }



  // json2xml (Method)
  // Takes a JSON object and return a XML representation
  //
  // Original code from:
  // http://jsfiddle.net/ARTsinn/cWK9Q/
  //
  // Adapted & improved by Victor Espina
  //
  this.json2xml = function (obj, rootname) {
    "use strict";
    var tag = function (name, closing) {
        return "<" + (closing ? "/" : "") + name + ">";
    };

    var xml = "";
    for (var i in obj) {
        if (obj.hasOwnProperty(i)) {
            var value = obj[i],
                type = typeof value;
            if (value instanceof Array && type == 'object') {
                xml += tag(i);
                for (var sub in value) {
                    xml += this.json2xml(value[sub], "item");
                }
                xml += tag(i, {closing: 1});
            } else if (value instanceof Object && type == 'object') {
                xml += tag(i) + this.json2xml(value) + tag(i, 1);
            } else {
                xml += tag(i) + value + tag(i, {
                    closing: 1
                });
            }
        }
    }

    return rootname ? tag(rootname) + xml + tag(rootname, 1) : xml;
  }




  // html (Method)
  // Returns a function for html building
  //
  // USAGE:
  // var html = avfp.html("some-html");
  // html.append("more-html");
  // html.append("#domElement");
  // html.append("html-template", {values});
  // $(element).html( html.content() );
  //
  this.html = function(dom) {

    var instance = {
      dom: null,

      constructor: function(dom) {
        if (!dom) dom = "<div></div>";
        if (dom[0] == "#") dom = $(dom);
        this.dom = $(dom);
      },

      empty: function() {
        this.dom.empty();
      },

      isEmpty: function() {
        return (this.dom.html().length == 0);
      },

      append: function(html, params) {
        if (html[0] == "#") html = $(html);
        if (params)
          html = avfp.template(html).render(params);
        this.dom.append(html);
      },

      content: function() {
        return this.dom.html();
      }

    }

    instance.constructor(dom);

    return instance;
  }


  // template (Method)
  // Returns a function for template rendering
  //
  // USAGE:
  // var templ = avfp.template("<div id='{id}' class='{cssclass}'>{content}</div>");
  // var html = templ.render({
  //    id: "myDiv",
  //    cssclass: "panel bordered",
  //    content: $("#myDivContent").html()
  // });
  //
  this.template = function(dom, defaults) {

    var instance = {
      dom: "",
      _attrs: [],
      _def: {},

      constructor: function(html, defaults) {
        if (dom) this.dom = (dom[0] == "#") ? $(dom).html() : dom;
        if (defaults) this._def = defaults;
        this.analizeDOM();
      },

      analizeDOM: function() {
        this._attrs = [];
        var attr = "";
        var inattr = false;
        for (var i = 0; i<this.dom.length; i++) {
          var c = this.dom[i];
          switch (c) {
            case "{":
              attr = "";
              inattr = true;
              break;

            case "}":
              if (this._attrs.indexOf(attr) < 0) {
                this._attrs.push(attr);
                this[attr] = "";
              }
              inattr = false;

            default:
              if (inattr) attr = attr + c;
              break;
          }
        }
      },


      render: function(attrs) { 

        // If user provided with a customized DOM, we
        // 
        if (attrs && attrs.dom) {
          this.dom = (dom[0] == "#") ? $(dom).html() : dom;
          this.analizeDOM();
          attrs.dom = null;
        }
        if (!attrs) attrs = this._def;

        var html = this.dom;
        for (var i = 0; i < this._attrs.length; i++) {
          var attr = this._attrs[i];      
          var ph = "{" + attr + "}";
          var value = (attrs) ? attrs[attr] : this[attr];
          if (value == null) value = "";
          while (html.indexOf(ph) >= 0) {
            html = html.replace(ph, value);
          }
        }
        return html;
      }

    }

    instance.constructor(dom, defaults);

    return instance;
  }





}


// avfpModal (class)
// Represents a modal customizable dialog
//
// MAINTAINED BY BACKWARD COMPATIBILITY
// Use avfp.bs.modal() instead.
//
function avfpModal() {

    this.id = "#modalDialog";
    this.ui = function() { return $(avfp.modal.id); };
    this.options = {
      title: "",
      message: "",
      style: "default",      
      okButton: "Dismiss",
      cancelButton: null,
      customButton: null,
      okButtonClass: "primary",
      cancelButtonClass: "default",
      customButtonClass: "danger",
      onOk: function(modal, source) { return true; },
      onCancel: function(modal, source) { return true; },
      onCustom: function(modal, source) { return true; },
      onShow: null
    };

    this.show = function(options) {
        var modal = $(this.id);
        var mtitle = modal.find(".modal-title");
        var mbody = modal.find(".modal-body");
        var mcustom = modal.find("#cmdModalCustom");
        var mcancel = modal.find("#cmdModalCancel");
        var mok = modal.find("#cmdModalOk");
        options = avfp.mergeObjects(this.options, options);

        if (options.message[0] == "#") options.message = $(options.message).html();  // If message starts with "#", use the indicated DOM element's HTML as dialog's body

        mtitle.html(options.title);
        mbody.html(options.message);

        if (options.customButton) {
          mcustom.html(options.customButton);
          mcustom.show();
          mcustom.on('click',function() { if (options.onCustom(modal, "custom")) avfp.modal.hide(); });
        } else {
          mcustom.hide();
          mcustom.off('click');
        }

        if (options.cancelButton) {
          mcancel.html(options.cancelButton);
          mcancel.on('click',function() { if (options.onCancel(modal, "cancel")) avfp.modal.hide(); });
        } else {
          mcancel.hide();
          mcancel.off('click');
        }

        mok.html(options.okButton);
        mok.on('click',function() { if (options.onOk(modal, "ok")) avfp.modal.hide(); });

        modal.find(".modal-content").removeClass().addClass("modal-content panel panel-" + options.style);
        if (options.onShow) modal.on('shown.bs.modal', function (e) { options.onShow(modal) });
        modal.modal();

    }


    this.hide = function() {
      var modal = $(this.id);
      var mbody = modal.find(".modal-body"); 
      var mcustom = modal.find("#cmdModalCustom");
      var mcancel = modal.find("#cmdModalCancel");
      var mok = modal.find("#cmdModalOk");
      mbody.html('');  // This is IMPORTANT to avoid duplicate element's id if modal content was copied from a DOM element
      modal.modal('hide');
      mok.off("click");
      mcancel.off("click");
      mcustom.off("click");
    }



}


function avfpBootstrapHelper() {

  this.callback = null;
  this.modalDialog = null;
  

  // modal (Method)
  // Shows a boostrap modal dialog
  //
  // Usage:
  // var modal = avfp.bsmodal([options]);
  // modal.show([bootstrap-modal-options]); 
  //
  // Options:
  // header: text or DOM ID
  // body: text or DOM id
  // footer: text or DOM id
  // dom: custom modal DOM (use it only if you know what you are doing)
  // size: SM, MD or LG  (defaults to MD)
  // modalCSS: css for modal-dialog div
  // headerCSS: css for modal-header div
  // bodyCSS: css for modal-body div
  // footerCSS: css for modal-footer div
  // onShow: function to call when the modal is shown
  // callback: callback function [1]
  //
  // [1] If a callback is defined, you can call the callback
  //     in a modal's button using vfp.callbacks.bsmodal. Also
  //     you can use avfp.modal.close() to close the current 
  //     modal dialog.
  //
  this.modal = function(options) { 

    if (arguments.length == 0) options = {};

    if (typeof options == "string" && options == "close") {
      if (this.modalDialog) this.modalDialog.modal("hide");
      return;
    }


    var header =  options.header || "Modal Dialog";
    var body = options.body || "This is a bootstrap modal dialog";
    var footer = options.footer || '<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>';
    var size = options.size || "md";
    var dom = options.dom ||
          '<div class="modal fade bs-example-modal-{size}" ' + 
          '    id="{id}" tabindex="-1"' +
          '    role="dialog" aria-hidden="true" data-backdrop="static">' +
          '    <div class="modal-dialog modal-{size}" style="{modalCSS}">' +
          '        <div class="modal-content">' +
          '           <div class="modal-header" style="{headerCSS}">'+
          '             <button type="button" class="close" data-dismiss="modal">&times;</button>'+
          '             <h4 class="modal-title">{header}</h4>'+
          '           </div>'+
          '           <div class="modal-body" style="{bodyCSS}">' +
          '              {body}'+
          '           </div>' +
          '           <div class="modal-footer style={footerCSS}">' +
          '              {footer}'+
          '           </div>'+
          '        </div>' +
          '    </div>' +
          '</div>';
    var onShow = options.onShow || null;            
    var css = {
      modal: options.modalCSS || "",
      header: options.headerCSS || "",
      footer: options.footerCSS || "",
      body: options.bodyCSS || ""
    };

    if (header[0] == "#") header = $(header).html();
    if (body[0] == "#") body = $(body).html();
    if (footer[0] == "#") footer = $(footer).html();

    var html = avfp.template(dom).render({
      header: header,
      body: body,
      footer: footer,
      size: size,
      modalCSS: css.modal,
      headerCSS: css.header,
      bodyCSS: css.body,
      footerCSS: css.footer
    });

    this.modalDialog = $(html);
    this.modalDialog.modal(options);
    if (options.callback) this.callback = options.callback;
    if (onShow) onShow();
  }



  
  // render (ibject)
  // Common bootstrap renderers
  //
  this.render = {

    // button
    // Simple button
    //
    // USAGE:
    // html = avfp.bs.button({
    //  id: "myButton",
    //  button: "primary",
    //  caption: "This is a button",
    //  onclick: "alert('Clicked!');" 
    // });
    //
    // OPTIONS:
    // caption: button's caption
    // id: button's ID
    // button: button type (primary, danger, default)
    // size: button's size (lg, sm, xs)
    // cssclass: additional css classes
    // attrs: additional attributes
    // licon: button's left icon 
    // ricon: button's right icon
    // onclick: onclick event code
    //
    button: function(options) {
      options = (arguments.length > 0) ? options : {};
      var dom = options.dom || 
                '<button type="button" class="btn btn-{button} btn-{size} {cssclass}" {id} {attrs} onclick="{onclick}">'+
                ' {licon} {caption} {ricon}' + 
                '</button>';
      var id = (options.id) ? 'id="' + options.id + '"' : "";                
      return avfp.template(dom).render({
        button: options.button || "default",
        caption: options.caption || "button",
        size: options.size || "lg",
        cssclass: options.cssclass || "",
        id: id,
        attrs: options.attrs || "",
        licon: this.icon((options.licon) ? {icon: options.licon, attrs: "style='margin-right: 10px;'"} : null),
        ricon: this.icon((options.ricon) ? {icon: options.ricon, attrs: "style='margin-left: 10px;'"} : null),
        onclick: options.onclick || "alert('(not programmed)');"
      });
    },



    // icon
    // Simple non-clikable glyph icon
    //
    // USAGE:
    // html = avfp.bs.renders.icon({
    //   icon: "star"
    // });
    //
    // OPTIONS: 
    // icon: glyph image
    // cssclass: additional css classes
    // attrs: additional attributes
    // id: element's id
    //
    icon: function(options) { 
      if (!options) return "";
      var dom = options.dom || '<span class="glyphicon glyphicon-{icon} {cssclass}" aria-hidden="true" {id} {attrs}></span>';
      var id = (options.id) ? 'id="' + id + '"' : "";
      return avfp.template(dom).render({
        icon: options.icon || "star", 
        cssclass: options.cssclass || "",
        attrs: options.attrs || "",
        id: id
      });
    },

    // smallIconButton
    // Small glyph icon button
    //
    // USAGE:
    // html = avfp.bs.render.smallIconButton({
    //   icon: "plus",
    //   title: "Add Contact",
    //   onclick: "app.addContact();"
    // });
    //
    // OPTIONS:
    // icon: glyphicon image name
    // title: button title
    // cssclass: additional CSS classes
    // attrs: additional attributes
    // onclick: js code for onclick event
    //
    smallIconButton: function(options) {
      if (arguments.length == 0) options = {};
      var dom = options.dom || '<a href="#" class="glyphicon glyphicon-{icon} clickable {cssclass}" title="{title}" onclick="{onclick} {attrs}"></a>';
      return avfp.template(dom).render({
        icon: options.icon || "cog",
        title: options.title || "(not defined)",
        cssclass: options.cssclass || "",
        attrs: options.attrs || "",
        onclick: options.onclick || "alert('(not programmed)');"
      });
    },


    // dropDownMenuButton
    // Dropdown Menu Button
    //
    // USAGE:
    // html = avfp.bs.renders.dropDownMenuButton({
    //  id: "myMenu",
    //  caption: "My Menu",
    //  button: "primary",
    //  menu: [
    //          {caption: "Open", onclick: "app.open();"},
    //          {caption: "New", onclick: "app.new();"},
    //          {divider: true}, // Divider
    //          {caption: "Exit", onclick: "app.exit();", icon: "off"}
    //        ]
    // });
    //
    // OPTIONS:
    // id:  button tag id
    // caption: button's caption
    // button: button's class
    // size: button's size (lg, sm, xs)
    // cssclass: additional classes for button tag
    // attrs: additional attributes for button tag
    // menu: drop down menu options array
    //
    dropDownMenuButton: function(options) {
      if (arguments.length == 0) options = {};
      var dom = options.dom || 
                '<div class="dropdown">' + 
                '  <button class="btn btn-{button} btn-{size} dropdown-toggle {cssclass}" type="button" id="{id}" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true" {attrs}>'+
                '   {icon} {caption} <span class="caret"></span>' + 
                '  </button>' + 
                '  <ul class="dropdown-menu" aria-labelledby="{id}">' + 
                '    {menu}'+
                '  </ul>' + 
                '</div>';
      var items = options.options || [{caption: "(none)", onclick: ""}];
      if (options.icon) {
        options.icon = avfp.template('<span class="glyphicon glyphicon-{icon}" aria-hidden="true"></span>').render(options);
      }

      var menu = avfp.html();
      for (var i = 0; i < items.length; i++) {
        var item = items[i];
        if (!item.divider) {
          if (item.icon) {
            item.caption = avfp.template('<span class="glyphicon glyphicon-{icon}" aria-hidden="true"></span> {caption}').render(item);
          }
          menu.append('<li><a href="#" onclick="{onclick}">{caption}</a></li>', item);
        } else {
          menu.append('<li class="divider"></li>');
        }
      }

      return avfp.template(dom).render({
        button: options.button || "default",
        id: options.id || "dropDownMenu1",
        caption: options.caption || "",
        size: options.size || "lg",
        icon: options.icon || "",
        cssclass: options.cssclass || "",
        attrs: options.attrs || "",
        menu: menu.content()
      });

    },


    // optionsIconButton
    // Dropdown Menu Icon Button
    //
    // USAGE:
    // html = avfp.bs.renders.optionsIconButton({
    //  id: "myMenu",
    //  menu: [
    //          {caption: "Open", onclick: "app.open();"},
    //          {caption: "New", onclick: "app.new();"},
    //          {divider: true}, // Divider
    //          {caption: "Exit", onclick: "app.exit();", icon: "off"}
    //        ]
    // });
    //
    // OPTIONS:
    // id:  button tag id
    // icon: icon's image (default is "cog")
    // button: button's class
    // size: button's size (lg, sm, xs) (default is "sm")
    // cssclass: additional classes for button tag
    // attrs: additional attributes for button tag
    // menu: drop down menu options array
    //
    optionsIconButton: function(options) {
      options.caption = "";
      options.icon = options.icon || "cog";
      options.size = options.size || "sm";
      return this.dropDownMenuButton(options);
    }

  }

}



function avfpJqueryMobileHelper() {


  // render (object)
  // Common JQM renderers
  //
  this.render = {

    // button 
    // JQM Simple Rounded Button
    //
    // USAGE:
    // var html = avfp.jqm.renders.button({
    //    id: "cmdNew", 
    //    caption: "New", 
    //    onclick: "app.newRecord();"
    // });
    //
    // OPTIONS:
    // theme: theme swatch (a, b)
    // cssclass: additional CSS classes
    // id: button's id
    // onclick: button's onclick event
    // caption: button's caption
    //
    button: function(options) {
      var dom = '<button class="ui-btn ui-corner-all ui-btn-{theme} {cssclass}" id="{id}" onclick="{onclick}" {attrs}>'+
                ' {caption}'+
                '</button>';
      return avfp.template(dom, {theme: "a", id: "mybutton", caption: "My Button"})
                 .render(options || {});
    }


  }


}



