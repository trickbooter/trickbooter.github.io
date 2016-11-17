+++
draft = true
title = "2016 10 13 code highlighting"
date = "2016-11-13T16:28:48+11:00"

+++

```html
<section id="main">
  <div>
    <h1 id="title">{{ .Title }}</h1>
    {{ range .Data.Pages }}
      {{ .Render "summary"}}
    {{ end }}
  </div>
</section>
```

{{< highlight html >}}
<section id="main">
  <div>
    <h1 id="title">{{ .Title }}</h1>
    {{ range .Data.Pages }}
      {{ .Render "summary"}}
    {{ end }}
  </div>
</section>
{{< /highlight >}}


```scala
def x() : Unit = {
  val y = 1
  y
}
```

{{< highlight scala >}}
def x() : Unit = {
  val y = 1
  y
}
{{< /highlight >}}

```ruby
ADD x deec
ENV aa=rrr
```

```javascript
/**
 * Does a thing
 */
function helloWorld(param1, param2) {
  var something = 0;

  // Do something
  if (2.0 % 2 == something) {
    console.log('Hello, world!');
  } else {
    return null;
  }

  // @TODO comment
}
```
