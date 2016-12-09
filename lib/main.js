'use babel';

// import EmpProjectViewView from './emp-project-view';
import {$, $$} from 'atom-space-pen-views';
import { CompositeDisposable } from 'atom';
import { requirePackages } from 'atom-utils';
import EmpProjectNavigatorView from './emp-project-navigator-view';
import EmpToolBarView from './emp-tool-bar-view'
import ProjNavEventEmitter from './event-emitter'
import ProjectView from './emp-project-view'

export default {

  subscriptions: null,
  oToolBarView:null,
  oProjectView:null,

  activate(state) {
    console.log("EMP project view activated ~ ");
    this.state = state;
    // this.empProjectViewView = new EmpProjectViewView(state.empProjectViewViewState);
    // this.modalPanel = atom.workspace.addModalPanel({
    //   item: this.empProjectViewView.getElement(),
    //   visible: false
    // });
    //
    // // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();
    this.oEmitterRoute = new ProjNavEventEmitter()
    //
    // // Register command that toggles this view

    // atom.packages.activatePackage('tree-view').then((oTreeView)=>{
    //   console.log(oTreeView);
    //   let treeView = oTreeView.mainModule.createView();
    //   console.log(treeView);
    //   this.treeView = treeView[0]
    //   this.initialize()
    //
    // });

    requirePackages('tree-view').then(([treeView]) => {
      console.log(treeView);
      this.treeView = treeView;
      this.initialize()
    });
  },

  deactivate() {
    this.subscriptions.dispose();
    this.oEmitterRoute.dispose();
    // this.empProjectViewView.destroy();
  },

  serialize() {
    return {
      // empProjectViewViewState: this.empProjectViewView.serialize()
    };
  },

  initialize(){
    // this.oProjectView = new EmpProjectNavigatorView(this.state, this.treeView,this.oEmitterRoute)
    this.oProjectView = new ProjectView(this.state, this.treeView,this.oEmitterRoute)

    this.oToolBarView = new EmpToolBarView(this.treeView, this.oEmitterRoute);
    // this.show();
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'emp-project-view:toggle': () => this.show()
    }));

    $('body').on('focus', '.tree-view', ()=>{
      console.log("show tree view!");
      this.show()
    });

    $('body').on('focus', '.proj-view', ()=>{
      console.log("show proj view");
    });

    if (this.treeView.treeView && this.treeView.treeView.isVisible()) {
      this.show();
    }
  },

  show(){
    this.oToolBarView.show();
    // this.oProjectView.show()
  }


};
