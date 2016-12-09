'use babel';

import { CompositeDisposable } from 'atom'

import {React, ReactDOM} from 'react-for-atom'

class Panel extends React.Component {

  constructor(props){
    super(props)
    console.log("panel constructor!");
  }

  render(){
    console.log("do render");
    return <div className="panel-heading">An inset-panel heading</div>
  }

}

let modalPanel;

export default class ProjectNavigator {
  item = document.createElement('div');
  item =
  $('<div>').attr('id', 'emp-app-var').addClass('project-bar');

  init(faView){
    console.log(faView);
    let treeView = faView.treeView

    if (treeView && treeView.isVisible()) {
      this.treeView = treeView
      this.do_init()
    } else {

    }

    // modalPanel = atom.workspace.addRightPanel({
    //   item,visible: true});
    ReactDOM.render(
      <div>
      {/*<PanelHead />*/}
      <Panel />
      </div>,
      item
    )
  }

  do_init() {
    console.log("do initial");
    console.log(this.treeView.find('.project-root .list-tree .list-item'));
    this.treeView.before(this.item);
  }

  toggle(){
    console.log('LuaDebug was toggled! ');
    return (
      modalPanel.isVisible() ?
      modalPanel.hide() :
      modalPanel.show()
    );
  }

  show(){
    modalPanel.show();
    return;
  }

  hide(){
    modalPanel.hide();
    return;
  }

  dispose(){
    modalPanel.destroy();
    modalPanel = null;
  }


}
