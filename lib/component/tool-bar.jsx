'use babel';

import { CompositeDisposable } from 'atom'
import {$, $$, View,TextEditorView} from 'atom-space-pen-views';

import {React, ReactDOM} from 'react-for-atom'

export class ToolBar extends React.Component {

  constructor(props){
    // console.log((props));
    super(props);
    this.treeView = this.props.treeView;
    this.emitter = this.props.emitter;
    var tmpChildren = $(this.treeView).children()
    for (var i=0;i<tmpChildren.length;i++){
      var tmpChild = tmpChildren[i]
      // console.log(tmpChild.className);
      // console.log(tmpChild.className.match(/tree-view-scroller/ig));
      if (tmpChild.className.match(/tree-view-scroller/ig)) {
        this.treeScroller = tmpChild
      }
    }
    this.panelFile = "file";
    this.panelProj = "project";
    this.panelSearch = "search";
    // console.log(this.treeScroller);
    // console.log("panel constructor!");
    this.sSelectCss = "btn selected";
    this.sNormalCss = "btn";
    this.sSelected = " selected";
    this.sProjCss = "btn btn-proj";
    this.sProjSelCss = "btn btn-proj selected";
    this.sProjLeftCss = "btn btn-left";
    this.sProjRightCss = "btn btn-right icon icon-triangle-down";
    this.state = {"css":
      {
        "first":this.sSelectCss,
        "second":this.sProjCss,
        "secLeft":this.sProjLeftCss,
        "secRight":this.sProjRightCss,
        "third":this.sNormalCss

      }
    };
  }

  onBtnFile(){
    // console.log("click btn file !~~~~");
    this.state.css.first= this.sSelectCss;
    // this.state.css.second= this.sProjCss;
    this.state.css.secLeft= this.sProjLeftCss;
    this.state.css.secRight= this.sProjRightCss;
    this.state.css.third= this.sNormalCss;
    this.setState(this.state)
    this.emitter.emit('show-project-nav', {'panel':"file"});
    $(this.treeScroller).show()

  }

  onBtnProject(){

    console.log("click btn project !~~~~");
    this.state.css.first= this.sNormalCss;
    // this.state.css.second= this.sProjSelCss;
    this.state.css.secLeft= this.sProjLeftCss+this.sSelected;
    this.state.css.secRight= this.sProjRightCss+this.sSelected;
    this.state.css.third= this.sNormalCss;
    this.setState(this.state)
    $(this.treeScroller).hide()
    this.emitter.emit('show-project-nav', {'panel':"project"});
  }

  onBtnSearch(){
    // console.log("click btn Search !~~~~");
    this.state.css.first= this.sNormalCss;
    // this.state.css.second= this.sProjCss;
    this.state.css.secLeft= this.sProjLeftCss;
    this.state.css.secRight= this.sProjRightCss;
    this.state.css.third= this.sSelectCss;
    this.setState(this.state);
    this.emitter.emit('show-search-panel', {'panel':"search"});
  }

  onBtnProjList(){
    console.log("show project list !~~~~");

    this.state.css.first= this.sNormalCss;
    // this.state.css.second= this.sProjSelCss;
    this.state.css.secLeft= this.sProjLeftCss+this.sSelected;
    this.state.css.secRight= this.sProjRightCss+this.sSelected;
    this.state.css.third= this.sNormalCss;
    this.setState(this.state)
    $(this.treeScroller).hide()
    this.emitter.emit('show-project-nav', {'panel':"project"});
    // this.state.css.first= this.sNormalCss;
    // this.state.css.second= this.sNormalCss;
    // this.state.css.third= this.sSelectCss;
    // this.setState(this.state);
    // this.emitter.emit('show-search-panel', {'panel':"search"});
  }

  render(){
    // console.log("do render:", this.state);
    return (<div className="btn-group" >
      <button  className={this.state.css.first} onClick={this.onBtnFile.bind(this)} >File</button>
      <div className={this.state.css.second} >
      <button className={this.state.css.secLeft} onClick={this.onBtnProject.bind(this)}> Project</button>
      <button className={this.state.css.secRight} onClick={this.onBtnProjList.bind(this)} > </button>
      </div>
      <button className={this.state.css.third} onClick={this.onBtnSearch.bind(this)} >Search</button>
    </div>);
  }
}

// "btn-right icon icon-triangle-down"
      // <button className={this.state.css.second} onClick={this.onBtnProject.bind(this)} >Project</button>
