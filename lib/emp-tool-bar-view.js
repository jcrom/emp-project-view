'use babel';

// import $ from 'jquery';
import {Emitter } from 'atom'
import {$, $$, View,TextEditorView} from 'atom-space-pen-views';
import {React, ReactDOM} from 'react-for-atom'
import {ToolBar} from './component/tool-bar.jsx'

// import { CompositeDisposable } from 'atom';

export default class EmpToolBarView {
  state =false;
  atached=false;



  constructor(oTreeView, oEmitterRoute){
    // console.log("do constructor !", oTreeView);
    this.emitter = new Emitter()
    this.oTreeView = oTreeView;
    this.oEmitterRoute = oEmitterRoute;
    this.oEmitterRoute.doToolBarEmit(this)
    // this.panel = document.createElement('tag');
    // this.panel.classList.add('tool-panel');
    //
    this.element = document.createElement('div');
    this.element.classList.add('emp-project-view');

  }

  // Returns an object that can be retrieved when package is activated
  serialize() {}

  // Tear down any state and detach
  dispose(){
    this.destroy()
  }
  destroy() {
    this.atached = false;
    this.element.remove();
  }


  show(){
    // console.log(this.oTreeView);
    // console.log(this.oTreeView.treeView);
    if (!this.atached){
      this.atached = true;
      let treeView = this.oTreeView.treeView;
      // console.log(treeView);
      // console.log($(treeView));
      // console.log($(treeView).children());
      // console.log($(treeView).view());

      treeView.prepend(this.element);
      ReactDOM.render(
        <div className="block" >
          <ToolBar treeView={treeView} emitter={this.emitter}/>
        </div>,
        this.element
      )
    }
    // if (this.state){
    //   this.state=false;
    //   this.oTreeView.hide()
    //
    // } else {
    //   this.state = true;
    //   this.oTreeView.show()
    // }
  }

  hide() {
    this.element.hide()
  }

  // callback
  onToolBarSearch(callback){
    return this.emitter.on('show-search-panel', callback)
  }

  onToolBarProj(callback){
    return this.emitter.on('show-project-nav', callback)
  }

};
