class_name CourseData
extends RefCounted

const MAPS: Array[Dictionary] = [
	{"name": "糖果巡游", "en": "CANDY CARNIVAL", "tag": "新手推荐", "difficulty": 1, "desc": "跳过奶油平台，躲开旋转糖果棒！", "tip": "空格起跳越过旋转棒，按 Shift 滚动冲刺。", "color": "ee8eac", "floor": "f5b8c8", "edge": "d86d91", "sky": "bde4f3", "accent": "ffd36c", "gravity": 22.0, "ice": false, "layout": [0, 0, 2, -2, 0, 2, 0], "heights": [0, 0, 0.3, 0.3, 0, 0.5, 0.5], "kinds": ["none", "sweeper", "bumper", "gate", "sweeper", "bounce", "none"]},
	{"name": "冰淇淋雪原", "en": "FROSTY EXPRESS", "tag": "小心打滑", "difficulty": 2, "desc": "冰面会打滑，移动浮冰考验落点。", "tip": "冰面提前松开方向键，跳跃可以重新调整方向。", "color": "6bc4de", "floor": "b4e8ee", "edge": "5baac5", "sky": "c9e3f5", "accent": "eafafa", "gravity": 22.0, "ice": true, "layout": [0, 1, -2, 2, -1, 1, 0], "heights": [0, 0, 0.4, 0.2, 0.3, 0, 0], "kinds": ["none", "gate", "moving", "sweeper", "moving", "bumper", "none"]},
	{"name": "熔岩蹦蹦谷", "en": "LAVA LEAP", "tag": "勇气挑战", "difficulty": 3, "desc": "喷发火柱与限时石板，别在原地停太久。", "tip": "火柱亮起时从侧边绕行，发红的石板即将消失。", "color": "ef9667", "floor": "736d91", "edge": "52496c", "sky": "f3beab", "accent": "ffc55c", "gravity": 22.0, "ice": false, "layout": [0, -2, 2, 0, -2, 2, 0, 0], "heights": [0, 0.4, 0, 0.5, 0.3, 0.4, 0, 0], "kinds": ["none", "fire", "crumble", "sweeper", "fire", "crumble", "gate", "none"]},
	{"name": "云端游乐场", "en": "CLOUD HOPPERS", "tag": "向天空出发", "difficulty": 2, "desc": "弹跳云朵、漂浮小岛，一路飞向彩虹。", "tip": "青色弹床会自动起跳；空中也能控制落点。", "color": "b4a0e0", "floor": "e1d9f5", "edge": "a18cc7", "sky": "c7e5f4", "accent": "ffda88", "gravity": 18.0, "ice": false, "layout": [0, 2, -1, -3, 1, 3, 0, 0], "heights": [0, 0.7, 1.2, 1.0, 1.6, 1.2, 1.8, 1.8], "kinds": ["none", "bounce", "moving", "wind", "bounce", "moving", "sweeper", "none"]},
	{"name": "蘑菇森友会", "en": "JUNGLE JAM", "tag": "奇妙探险", "difficulty": 2, "desc": "穿过蘑菇森林，避开摆木与逆向传送带。", "tip": "传送带会推着你走，观察箭头后再起跳。", "color": "80bea0", "floor": "acd4a3", "edge": "679777", "sky": "cfebd2", "accent": "ffd49b", "gravity": 22.0, "ice": false, "layout": [0, -2, -3, 1, 3, -1, 0], "heights": [0, 0.2, 0.4, 0.4, 0.8, 0.3, 0.3], "kinds": ["none", "pendulum", "conveyor", "bumper", "pendulum", "bounce", "none"]},
	{"name": "星际失重站", "en": "COSMIC CRUISE", "tag": "低重力漫游", "difficulty": 3, "desc": "低重力长跳，穿梭星环与旋转激光。", "tip": "这里重力更低，提前起跳，注意空中漂移。", "color": "849ee2", "floor": "a2b4e1", "edge": "5c73ae", "sky": "879bc5", "accent": "b4f3e7", "gravity": 10.0, "ice": false, "layout": [0, 3, -2, -3, 2, 3, -1, 0], "heights": [0, 0.8, 1.5, 0.9, 1.8, 1.4, 2.0, 2.0], "kinds": ["none", "sweeper", "moving", "gate", "wind", "sweeper", "moving", "none"]}
]

const ITEMS: Array[Dictionary] = [
	{"name": "汽水加速", "short": "加速", "symbol": ">>", "color": "ffbf60", "desc": "6 秒疾跑，速度提升 65%。"},
	{"name": "泡泡护盾", "short": "护盾", "symbol": "O", "color": "7ecde7", "desc": "8 秒内免疫机关碰撞，无法抵挡坠落。"},
	{"name": "弹簧鞋", "short": "高跳", "symbol": "^^", "color": "ad9bec", "desc": "8 秒内跳得更高，轻松跨越断崖。"},
	{"name": "星星磁铁", "short": "磁铁", "symbol": "U", "color": "f18bac", "desc": "8 秒自动吸收附近的星星。"},
	{"name": "轻盈羽毛", "short": "羽毛", "symbol": "~", "color": "8fd9b3", "desc": "6 秒减缓下落，按住空格滑翔。"},
	{"name": "回溯甜甜圈", "short": "回溯", "symbol": "@", "color": "eaa66f", "desc": "立即回到最近的复活点，保留星星。"}
]

const SKINS: Array[Color] = [Color("ffd268"), Color("fa9fbd"), Color("81d6c5"), Color("a7b8f2"), Color("f6f0df")]
