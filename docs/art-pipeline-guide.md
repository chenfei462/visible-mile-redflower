# 美术资源接入指南

本项目的美术资源采用数据驱动接入：

`资源文件 -> data/art_manifest.json -> 数据中的 art_key/icon_key/portrait_key -> UI 加载`

## 目录约定

- `res://assets/cards`
- `res://assets/icons`
- `res://assets/portraits`
- `res://assets/events`

默认建议命名：

- `card_xxx` -> `res://assets/cards/card_xxx.png`
- `icon_xxx` -> `res://assets/icons/icon_xxx.png`
- `portrait_xxx` -> `res://assets/portraits/portrait_xxx.png`

## 接入步骤

1. 把图片放进对应目录
2. 打开 Godot，让资源自动导入
3. 在 `data/art_manifest.json` 中为资源补条目
4. 在 `data/cards.json`、`data/residents.json` 或事件数据中引用对应 key
5. 运行 `run_tests.bat`

## art_manifest 条目示例

```json
{
  "card_ramp_blueprint": {
    "kind": "card",
    "path": "res://assets/cards/card_ramp_blueprint.png",
    "placeholder_path": "res://icon.svg",
    "fallback_label": "坡道建筑许可"
  },
  "icon_ramp_blueprint": {
    "kind": "icon",
    "path": "res://assets/icons/icon_ramp_blueprint.png",
    "placeholder_path": "res://icon.svg",
    "fallback_label": "坡道建筑许可"
  }
}
```

## 校验

`DataRepository` 现在提供：

- `get_art_pipeline_contract()`
- `suggest_art_asset_path(resource_key, extension := "png")`
- `get_art_audit_report()`

其中 `get_art_audit_report()` 会告诉你：

- 哪些 manifest 条目还没配置自定义资源
- 哪些配置了 `path` 但资源文件不存在

## 建议

- 图标优先透明底 PNG
- 小图优先可识别轮廓，不要过度依赖细节
- 先补 `icon`，再补 `portrait`，最后补大卡面
