'use babel';

import { CompositeDisposable } from 'atom'
import {$, $$, View,TextEditorView} from 'atom-space-pen-views';

import {React, ReactDOM} from 'react-for-atom'

export class ProjTreeView extends React.Component {
  constructor(props){
    console.log((props));
    super(props);
    // this.props.roots 0
    // console.log(this.state);
    // console.log(this.refs.lists)
    // this.roots = props.roots[0]
    // this.refs.lists.appendChild(this.roots)

    // this.treeView = this.props.treeView;
  }

  // show(){
  //   this.refs.lists.appendChild(this.roots)
  // }

  render(){
    // console.log("do render:", this.state);
    return <ol id="project_tree_view" className="proj-view full-menu list-tree has-collapsable-children focusable-panel" tabindex="-1" ref="lists" >

        </ol>
  }



}
