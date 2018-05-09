import './feather/feather.scss'
import feather from 'feather-icons/dist/feather'

window.feater = feather

$(() => {
  const replace = () => {
    Array.from(document.getElementsByClassName("feather"), element => {
      const iconname = Array.from(element.classList).find(clazz => clazz.indexOf("f-") != -1)
      
      if(iconname == undefined)return
      element.classList.remove(iconname)
      element.parentNode.replaceChild(new DOMParser().parseFromString(
        feather.icons[iconname.split("f-")[1]].toSvg(),
        'image/svg+xml'
      ).querySelector('svg'), element)
    })
  }
  $(document.body).on("crud:DOMChange", replace)
  replace()
})